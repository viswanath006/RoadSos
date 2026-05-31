from fastapi import APIRouter

from app.api.v1 import auth, contacts, incidents, services, sos, users

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(sos.router)
api_router.include_router(services.router)
api_router.include_router(contacts.router)
api_router.include_router(incidents.router)
