from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.service import NearbyServiceOut


class SosTriggerRequest(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    address_text: str | None = None


class SosTriggerResponse(BaseModel):
    incident_id: UUID
    message: str
    maps_link: str
    nearby_services: list[NearbyServiceOut]
    contacts_notified: int
