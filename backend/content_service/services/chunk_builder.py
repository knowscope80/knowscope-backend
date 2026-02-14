import re
from app.database import topics_collection, chunks_collection
from services.embedding_service import generate_embedding


def split_into_chunks(text: str, max_words=400, overlap=50):
    words = text.split()
    chunks = []

    start = 0
    while start < len(words):
        end = start + max_words
        chunk_words = words[start:end]
        chunk_text = " ".join(chunk_words)
        chunks.append(chunk_text)
        start += max_words - overlap

    return chunks


async def build_chunks(book_id: str):
    topics = await topics_collection.find(
        {"book_id": book_id}
    ).to_list(None)

    for topic in topics:
        text = re.sub(r"\s+", " ", topic["text"]).strip()

        if len(text.split()) < 150:
            continue

        chunks = split_into_chunks(text)

        for idx, chunk in enumerate(chunks):
            embedding = await generate_embedding(chunk)

            doc = {
                "book_id": book_id,
                "chapter_index": topic["chapter_index"],
                "chapter_title": topic["chapter_title"],
                "topic_index": topic["topic_index"],
                "topic_title": topic["title"],
                "chunk_index": idx + 1,
                "text": chunk,
                "embedding": embedding   # 👈 IMPORTANT
            }

            await chunks_collection.insert_one(doc)
