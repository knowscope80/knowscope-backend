from fastapi import APIRouter, UploadFile, File
import os
import tempfile

from app.database import raw_pages_collection
# from app.services.pdf_loader import extract_pages
from services.pdf_loader import extract_pages

router = APIRouter(prefix="/ingest", tags=["Ingestion"])

@router.post("/pdf")
async def ingest_pdf(file: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    pages = extract_pages(tmp_path)

    if pages:
        await raw_pages_collection.insert_many(pages)

    os.unlink(tmp_path)

    return {
        "pages_extracted": len(pages)
    }
