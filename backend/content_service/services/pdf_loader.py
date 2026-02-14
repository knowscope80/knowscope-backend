import pdfplumber

def extract_pages(pdf_path: str):
    pages = []

    with pdfplumber.open(pdf_path) as pdf:
        for idx, page in enumerate(pdf.pages):
            text = page.extract_text()
            if text and len(text.strip()) > 30:
                pages.append({
                    "page": idx + 1,
                    "text": text.strip()
                })

    return pages
