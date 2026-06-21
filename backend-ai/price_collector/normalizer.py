def normalize_text(value: str) -> str:
    if value is None:
        return "N/A"
    cleaned = str(value).strip()
    if not cleaned:
        return "N/A"
    return cleaned

def parse_price_tnd(value: str) -> float:
    if value is None:
        return 0.0
    value = str(value).strip().upper()
    value = value.replace("TND", "").replace("DT", "").strip()
    value = value.replace(" ", "")
    # Handle comma as decimal point if it exists
    value = value.replace(",", ".")
    try:
        return float(value)
    except ValueError:
        return 0.0

def normalize_quality_level(value=None) -> str:
    return "unknown"
