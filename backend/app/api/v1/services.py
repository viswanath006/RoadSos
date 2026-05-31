from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.service import ServiceCategory
from app.schemas.service import NearbyServiceOut
from app.services.nearby_service import NearbyService

router = APIRouter(prefix="/services", tags=["services"])


@router.get("/nearby", response_model=list[NearbyServiceOut])
async def nearby_services(
    db: Annotated[AsyncSession, Depends(get_db)],
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    category: ServiceCategory | None = None,
    radius_m: int = Query(10000, ge=500, le=50000),
    limit: int = Query(20, ge=1, le=50),
):
    service = NearbyService(db)
    return await service.get_nearby(latitude, longitude, category, radius_m, limit)


@router.get("/categories")
async def list_categories(db: Annotated[AsyncSession, Depends(get_db)]):
    from app.repositories.service_repository import ServiceRepository

    return {"categories": await ServiceRepository(db).get_categories()}
