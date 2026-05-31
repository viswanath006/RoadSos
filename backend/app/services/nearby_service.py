from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.service import ServiceCategory
from app.repositories.service_repository import ServiceRepository
from app.schemas.service import NearbyServiceOut


class NearbyService:
    def __init__(self, db: AsyncSession):
        self.repo = ServiceRepository(db)

    async def get_nearby(
        self,
        latitude: float,
        longitude: float,
        category: ServiceCategory | None = None,
        radius_m: int | None = None,
        limit: int = 20,
    ) -> list[NearbyServiceOut]:
        radius = radius_m or settings.sos_default_radius_m
        rows = await self.repo.find_nearby(latitude, longitude, radius, category, limit)
        return [
            NearbyServiceOut(
                id=s.id,
                name=s.name,
                category=s.category,
                distance_m=round(dist, 1),
                phone=s.phone,
                latitude=s.latitude,
                longitude=s.longitude,
                address=s.address,
            )
            for s, dist in rows
        ]
