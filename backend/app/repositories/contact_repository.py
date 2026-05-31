import uuid

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.contact import EmergencyContact


class ContactRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_by_user(self, user_id: uuid.UUID) -> list[EmergencyContact]:
        result = await self.db.execute(
            select(EmergencyContact)
            .where(EmergencyContact.user_id == user_id)
            .order_by(EmergencyContact.is_primary.desc(), EmergencyContact.sort_order)
        )
        return list(result.scalars().all())

    async def get_by_id(self, contact_id: uuid.UUID, user_id: uuid.UUID) -> EmergencyContact | None:
        result = await self.db.execute(
            select(EmergencyContact).where(
                EmergencyContact.id == contact_id,
                EmergencyContact.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def create(
        self, user_id: uuid.UUID, contact_name: str, phone: str, is_primary: bool
    ) -> EmergencyContact:
        if is_primary:
            await self.db.execute(
                update(EmergencyContact)
                .where(EmergencyContact.user_id == user_id)
                .values(is_primary=False)
            )
        contact = EmergencyContact(
            user_id=user_id,
            contact_name=contact_name,
            phone=phone,
            is_primary=is_primary,
        )
        self.db.add(contact)
        await self.db.flush()
        await self.db.refresh(contact)
        return contact

    async def update_contact(self, contact: EmergencyContact, **kwargs) -> EmergencyContact:
        if kwargs.get("is_primary"):
            await self.db.execute(
                update(EmergencyContact)
                .where(EmergencyContact.user_id == contact.user_id)
                .values(is_primary=False)
            )
        for key, value in kwargs.items():
            if value is not None:
                setattr(contact, key, value)
        await self.db.flush()
        await self.db.refresh(contact)
        return contact

    async def delete(self, contact: EmergencyContact) -> None:
        await self.db.delete(contact)
