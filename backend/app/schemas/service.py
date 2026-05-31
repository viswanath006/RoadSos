from uuid import UUID

from pydantic import BaseModel

from app.models.service import ServiceCategory


class NearbyServiceOut(BaseModel):
    id: UUID
    name: str
    category: ServiceCategory
    distance_m: float
    phone: str | None
    latitude: float
    longitude: float
    address: str | None = None
    eta_minutes: float | None = None
