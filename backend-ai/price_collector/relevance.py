import unicodedata
from typing import Tuple

def normalize_for_filter(text: str) -> str:
    """Normalize text by lowercasing and removing accents."""
    text = text.lower()
    text = unicodedata.normalize('NFD', text).encode('ascii', 'ignore').decode('utf-8')
    return text

def is_relevant_part(part_category: str, product_title: str) -> Tuple[bool, str]:
    """
    Check if a product is relevant to the requested part category.
    Returns (True, reason) if relevant, (False, reason) if not.
    """
    title_norm = normalize_for_filter(product_title)
    category_norm = normalize_for_filter(part_category)
    
    positive_keywords = []
    negative_keywords = []
    
    if category_norm == "phare":
        positive_keywords = [
            "phare", "optique", "projecteur", "feu", "feu avant", 
            "bloc optique", "eclairage", "lampe", "lamp"
        ]
        negative_keywords = [
            "cardan", "courroie", "bouton", "vitre", "leve vitre", "filtre", 
            "huile", "frein", "plaquette", "disque", "amortisseur", 
            "radiateur", "embrayage", "bougie", "alternateur", "demarreur"
        ]
    elif category_norm == "pneu":
        positive_keywords = ["pneu", "pneumatique", "roue"]
    elif category_norm == "pare-brise" or category_norm == "pare brise":
        positive_keywords = ["pare-brise", "pare brise", "vitrage", "glace"]
        negative_keywords = ["essuie", "balai", "liquide"]
    elif category_norm == "pare-chocs" or category_norm == "pare chocs":
        positive_keywords = ["pare-chocs", "pare chocs", "bouclier"]
    elif category_norm == "peinture":
        positive_keywords = ["peinture", "bombe", "stylo retouche", "vernis"]
    else:
        positive_keywords = [category_norm]

    # Check negative keywords first
    for neg in negative_keywords:
        if neg in title_norm:
            has_positive = any(pos in title_norm for pos in positive_keywords)
            if not has_positive:
                return False, f"contains negative keyword: {neg}"
            else:
                # Reject anyway for safety if negative is present, unless we want strict override
                # The prompt: "If a negative keyword appears and no strong positive keyword appears, reject."
                # We will accept if strong positive exists, so let's continue to positive check.
                pass

    # Check positive keywords
    for pos in positive_keywords:
        if pos in title_norm:
            return True, f"matched positive keyword: {pos}"
            
    return False, "missing positive part keyword"
