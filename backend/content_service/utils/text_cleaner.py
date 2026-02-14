import re

HEADER_FOOTER_PATTERNS = [
    r"Government of Kerala",
    r"SCERT",
    r"Standard\s+X{1,2}",
]

def normalize_text(text: str) -> str:
    text = text.replace("\x0c", " ")  # PDF artifacts
    text = re.sub(r"\n{2,}", "\n", text)

    for pattern in HEADER_FOOTER_PATTERNS:
        text = re.sub(pattern, "", text, flags=re.IGNORECASE)

    text = re.sub(r"\s{2,}", " ", text)
    return text.strip()
