from uuid import UUID

from pydantic import BaseModel, Field


class ContactCreate(BaseModel):
    contact_name: str = Field(min_length=1, max_length=120)
    phone: str = Field(min_length=10, max_length=20)
    is_primary: bool = False


class ContactUpdate(BaseModel):
    contact_name: str | None = None
    phone: str | None = None
    is_primary: bool | None = None


class ContactOut(BaseModel):
    id: UUID
    contact_name: str
    phone: str
    is_primary: bool
    sort_order: int

    model_config = {"from_attributes": True}
