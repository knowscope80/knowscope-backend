import asyncio
import sys
from services.chunk_builder import build_chunks


async def main(book_id: str):
    await build_chunks(book_id)
    print("Chunks created")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python run_chunk_pipeline.py <book_id>")
        sys.exit(1)

    book_id = sys.argv[1]
    asyncio.run(main(book_id))
