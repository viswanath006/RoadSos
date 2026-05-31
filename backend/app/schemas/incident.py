from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.models.incident import IncidentStatus


class IncidentOut(BaseModel):
    id: UUID
    latitude: float
    longitude: float
    address_text: str | None
    status: IncidentStatus
    triggered_at: datetime

    model_config = {"from_attributes": True}
