import uuid

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.service import Service, ServiceCategory


class ServiceRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def find_nearby(
        self,
        latitude: float,
        longitude: float,
        radius_m: int = 10000,
        category: ServiceCategory | None = None,
        limit: int = 20,
    ) -> list[tuple[Service, float]]:
        point = func.ST_SetSRID(func.ST_MakePoint(longitude, latitude), 4326)
        user_geog = func.ST_GeogFromWKB(func.ST_AsBinary(point))

        distance_expr = func.ST_Distance(Service.geom, user_geog).label("distance_m")

        query = (
            select(Service, distance_expr)
            .where(func.ST_DWithin(Service.geom, user_geog, radius_m))
            .order_by(distance_expr)
            .limit(limit)
        )
        if category:
            query = query.where(Service.category == category)

        result = await self.db.execute(query)
        rows = result.all()
        return [(row[0], float(row[1])) for row in rows]

    async def get_categories(self) -> list[str]:
        return [c.value for c in ServiceCategory]
