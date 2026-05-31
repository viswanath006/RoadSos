import uuid
from datetime import datetime
from enum import Enum

from geoalchemy2 import Geography
from sqlalchemy import DateTime, Enum as SAEnum, Float, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class ServiceCategory(str, Enum):
    hospital = "hospital"
    trauma_center = "trauma_center"
    ambulance = "ambulance"
    police = "police"
    towing = "towing"
    mechanic = "mechanic"
    puncture_shop = "puncture_shop"


class Service(Base):
    __tablename__ = "services"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(200))
    category: Mapped[ServiceCategory] = mapped_column(SAEnum(ServiceCategory, name="service_category", create_type=False))
    latitude: Mapped[float] = mapped_column(Float)
    longitude: Mapped[float] = mapped_column(Float)
    geom: Mapped[str] = mapped_column(Geography(geometry_type="POINT", srid=4326))
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata_: Mapped[dict | None] = mapped_column("metadata", JSONB, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
