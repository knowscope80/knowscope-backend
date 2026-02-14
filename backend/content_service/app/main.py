# from fastapi import FastAPI
# from app.routes.ingest import router as ingest_router

# app = FastAPI(title="Knowscope Content Service")

# app.include_router(ingest_router)

# @app.get("/")
# async def root():
#     return {"status": "content service running"}


from fastapi import FastAPI
from routes.ingest import router as ingest_router

app = FastAPI(title="Knowscope Content Service")

app.include_router(ingest_router)

@app.get("/")
async def root():
    return {"status": "content service running"}