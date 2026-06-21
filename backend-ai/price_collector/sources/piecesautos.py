import requests
from bs4 import BeautifulSoup
from datetime import datetime
import urllib3

# Suppress insecure request warnings for prototype
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from ..models import CollectedPart
from ..normalizer import normalize_text, parse_price_tnd, normalize_quality_level

def search_piecesautos(make: str, model: str, year: int, part_category: str) -> list:
    """
    Search PiecesAutos.tn for a given part and vehicle.
    Returns a list of CollectedPart objects.
    """
    query = f"{part_category} {make} {model}"
    url = "https://www.piecesautos.tn/"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
    }
    
    params = {
        "s": query,
        "post_type": "product"
    }
    
    results = []
    
    try:
        response = requests.get(url, params=params, headers=headers, timeout=10, verify=False)
        
        if response.status_code != 200:
            print(f"PiecesAutos returned status code {response.status_code}")
            return []
            
        soup = BeautifulSoup(response.text, "html.parser")
        
        products = soup.select(".product, .item, .product-item, .ty-column3")
        
        if not products:
            print("No clear product selectors found for PiecesAutos. The site may require JavaScript, have different selectors, or the search returned no results.")
            
        for product in products[:5]:
            title_el = product.select_one(".product-title, .title, h2, h3, .name, .woocommerce-loop-product__title")
            price_el = product.select_one(".price, .amount, .ty-price-num, .woocommerce-Price-amount")
            img_el = product.select_one("img")
            link_el = product.select_one("a")
            
            title = normalize_text(title_el.text) if title_el else "N/A"
            if title == "N/A" and link_el and link_el.text.strip():
                title = normalize_text(link_el.text)
                
            price_text = price_el.text if price_el else "0"
            price_tnd = parse_price_tnd(price_text)
            
            img_url = img_el.get("src") or img_el.get("data-src") if img_el else "N/A"
            product_url = link_el.get("href") if link_el else "N/A"
            
            if title == "N/A" and price_tnd == 0.0:
                continue
                
            part = CollectedPart(
                source="piecesautos",
                source_url=product_url,
                image_url=img_url,
                make=make,
                model=model,
                year=year,
                part_category=part_category,
                part_name=title,
                part_brand="N/A",
                reference="N/A",
                price_tnd=price_tnd,
                availability="N/A",
                condition="N/A",
                quality_level=normalize_quality_level(),
                collected_at=datetime.now().isoformat()
            )
            results.append(part)
            
    except requests.exceptions.RequestException as e:
        print(f"Error fetching from PiecesAutos: {e}")
        
    return results
