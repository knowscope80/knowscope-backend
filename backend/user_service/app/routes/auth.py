import os
from datetime import datetime, timedelta

from dotenv import load_dotenv
from fastapi import APIRouter, Body, Depends, Header, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, ExpiredSignatureError, jwt

from app.auth.google import verify_google_token
from app.crud import create_user, get_user_by_google_id, serialize_user
from app.database import blacklist_collection, users_collection
from app.schemas import AuthResponse, GoogleAuthRequest
from .jwt_handler import create_access_token, get_current_user

load_dotenv()
security = HTTPBearer()


async def get_user_from_header(authorization: str = Header(...)):
    print("Authorization header received:", authorization)
    token = authorization.split(" ")[1]
    try:
        return get_current_user(token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))


SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = os.getenv("JWT_ALGORITHM")

auth_router = APIRouter(prefix="/auth", tags=["auth"])


@auth_router.post("/google/auth", response_model=AuthResponse)
async def google_auth(payload: GoogleAuthRequest):
    try:
        user_data = verify_google_token(payload.token)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Google token")

    user = await get_user_by_google_id(user_data["google_id"])
    if not user:
        user = await create_user(user_data)

    serialized_user = serialize_user(user)

    access_token = create_access_token(
        {
            "user_id": serialized_user["id"],
            "email": serialized_user["email"],
            "role": serialized_user["role"],
        }
    )

    return {"access_token": access_token, "user": serialized_user}


@auth_router.post("/logout")
async def logout(
    refresh_token: str = Body(...),
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    access_token = credentials.credentials
    try:
        access_payload = jwt.decode(access_token, SECRET_KEY, algorithms=[ALGORITHM])
        if access_payload.get("type") != "access":
            raise HTTPException(status_code=400, detail="Invalid access token")
        refresh_payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        if refresh_payload.get("type") != "refresh":
            raise HTTPException(status_code=400, detail="Invalid refresh token")

        await blacklist_collection.insert_one(
            {
                "token": access_token,
                "expires_at": datetime.utcfromtimestamp(access_payload["exp"]),
            }
        )

        await blacklist_collection.insert_one(
            {
                "token": refresh_token,
                "expires_at": datetime.utcfromtimestamp(refresh_payload["exp"]),
            }
        )
        return {"message": "Logged out successfully"}
    except ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


@auth_router.get("/CurrentCurrentAuthenticatedperson")
async def get_authenticated_user(current_user: dict = Depends(get_user_from_header)):
    return {"message": "Authenticated user details", "user": current_user}


@auth_router.get("/auth_alluser", response_model=list[dict])
async def get_all_users():
    users: list[dict] = []
    cursor = users_collection.find({})
    async for user in cursor:
        users.append(serialize_user(user))
        print(user)
    return users


@auth_router.get("/auth_recent_users", response_model=list[dict])
async def get_recent_users(limit: int = 10):
    users: list[dict] = []
    cursor = users_collection.find({}).sort("_id", -1).limit(limit)

    async for user in cursor:
        users.append(serialize_user(user))
    return users

