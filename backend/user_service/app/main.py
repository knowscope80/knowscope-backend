from fastapi import FastAPI
from app.routes import router

app = FastAPI(title="Knowscope User Service")

app.include_router(router)

@app.get("/")
async def root():
    return {"status": "user service running"}
