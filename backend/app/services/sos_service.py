import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.service import ServiceCategory
from app.repositories.contact_repository import ContactRepository
from app.repositories.incident_repository import IncidentRepository
from app.repositories.service_repository import ServiceRepository
from app.schemas.service import NearbyServiceOut
from app.schemas.sos import SosTriggerResponse

SOS_MESSAGE_TEMPLATE = """Emergency Alert!

Possible road accident or emergency detected.

Current Location:
{maps_link}

Address: {address}

Please contact me immediately."""


class SosService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.incidents = IncidentRepository(db)
        self.services = ServiceRepository(db)
        self.contacts = ContactRepository(db)

    def _maps_link(self, lat: float, lng: float) -> str:
        return f"https://maps.google.com/?q={lat},{lng}"

    async def trigger(
        self,
        user_id: uuid.UUID,
        latitude: float,
        longitude: float,
        address_text: str | None,
    ) -> SosTriggerResponse:
        incident = await self.incidents.create_incident(
            user_id, latitude, longitude, address_text
        )

        priority_categories = [
            ServiceCategory.hospital,
            ServiceCategory.trauma_center,
            ServiceCategory.ambulance,
            ServiceCategory.police,
        ]
        nearby: list[NearbyServiceOut] = []
        seen_ids: set[uuid.UUID] = set()

        for category in priority_categories:
            rows = await self.services.find_nearby(
                latitude,
                longitude,
                radius_m=settings.sos_default_radius_m,
                category=category,
                limit=2,
            )
            for service, distance_m in rows:
                if service.id in seen_ids:
                    continue
                seen_ids.add(service.id)
                nearby.append(
                    NearbyServiceOut(
                        id=service.id,
                        name=service.name,
                        category=service.category,
                        distance_m=round(distance_m, 1),
                        phone=service.phone,
                        latitude=service.latitude,
                        longitude=service.longitude,
                        address=service.address,
                    )
                )

        user_contacts = await self.contacts.list_by_user(user_id)
        notified = await self.incidents.queue_alerts(incident.id, user_contacts)

        maps_link = self._maps_link(latitude, longitude)
        message = SOS_MESSAGE_TEMPLATE.format(
            maps_link=maps_link,
            address=address_text or "GPS coordinates only",
        )

        return SosTriggerResponse(
            incident_id=incident.id,
            message=message,
            maps_link=maps_link,
            nearby_services=nearby,
            contacts_notified=notified,
        )
