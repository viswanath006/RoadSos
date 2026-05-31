from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    phone: str = Field(min_length=10, max_length=20)
    email: EmailStr | None = None
    password: str = Field(min_length=6, max_length=128)


class UserLogin(BaseModel):
    phone: str
    password: str


class TokenRefresh(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: UUID
    name: str
    phone: str
    email: str | None

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserOut
