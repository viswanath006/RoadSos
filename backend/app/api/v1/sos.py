from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.sos import SosTriggerRequest, SosTriggerResponse
from app.services.sos_service import SosService

router = APIRouter(prefix="/sos", tags=["sos"])


@router.post("/trigger", response_model=SosTriggerResponse)
async def trigger_sos(
    data: SosTriggerRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    service = SosService(db)
    return await service.trigger(
        current_user.id,
        data.latitude,
        data.longitude,
        data.address_text,
    )
