from pydantic import BaseModel, EmailStr

class GoogleAuthRequest(BaseModel):
    token: str

class UserResponse(BaseModel):
    id: str
    email: EmailStr
    name: str | None = None
    picture: str | None = None

class AuthResponse(BaseModel):
    access_token: str
    user: UserResponse