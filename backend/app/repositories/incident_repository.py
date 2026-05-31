import uuid
from datetime import datetime, timezone

from geoalchemy2.elements import WKTElement
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.incident import Incident, IncidentStatus, SosAlert
from app.models.contact import EmergencyContact


class IncidentRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_incident(
        self,
        user_id: uuid.UUID,
        latitude: float,
        longitude: float,
        address_text: str | None,
    ) -> Incident:
        geom = WKTElement(f"POINT({longitude} {latitude})", srid=4326)
        incident = Incident(
            user_id=user_id,
            latitude=latitude,
            longitude=longitude,
            geom=geom,
            address_text=address_text,
            status=IncidentStatus.triggered,
        )
        self.db.add(incident)
        await self.db.flush()
        await self.db.refresh(incident)
        return incident

    async def list_by_user(self, user_id: uuid.UUID) -> list[Incident]:
        result = await self.db.execute(
            select(Incident).where(Incident.user_id == user_id).order_by(Incident.triggered_at.desc())
        )
        return list(result.scalars().all())

    async def get_by_id(self, incident_id: uuid.UUID, user_id: uuid.UUID) -> Incident | None:
        result = await self.db.execute(
            select(Incident).where(Incident.id == incident_id, Incident.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def queue_alerts(self, incident_id: uuid.UUID, contacts: list[EmergencyContact]) -> int:
        now = datetime.now(timezone.utc)
        count = 0
        for contact in contacts:
            alert = SosAlert(
                incident_id=incident_id,
                contact_id=contact.id,
                channel="app",
                status="sent",
                sent_at=now,
            )
            self.db.add(alert)
            count += 1
        await self.db.flush()
        return count
