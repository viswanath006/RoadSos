import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.repositories.contact_repository import ContactRepository
from app.schemas.contact import ContactCreate, ContactOut, ContactUpdate

router = APIRouter(prefix="/contacts", tags=["contacts"])


@router.get("/", response_model=list[ContactOut])
async def list_contacts(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    repo = ContactRepository(db)
    contacts = await repo.list_by_user(current_user.id)
    return [ContactOut.model_validate(c) for c in contacts]


@router.post("/", response_model=ContactOut, status_code=status.HTTP_201_CREATED)
async def create_contact(
    data: ContactCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    contact = await ContactRepository(db).create(
        current_user.id, data.contact_name, data.phone, data.is_primary
    )
    return ContactOut.model_validate(contact)


@router.put("/{contact_id}", response_model=ContactOut)
async def update_contact(
    contact_id: uuid.UUID,
    data: ContactUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    repo = ContactRepository(db)
    contact = await repo.get_by_id(contact_id, current_user.id)
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    updated = await repo.update_contact(
        contact,
        **data.model_dump(exclude_unset=True),
    )
    return ContactOut.model_validate(updated)


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_contact(
    contact_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    repo = ContactRepository(db)
    contact = await repo.get_by_id(contact_id, current_user.id)
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    await repo.delete(contact)
