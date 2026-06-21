import requests
from bs4 import BeautifulSoup
from datetime import datetime
import urllib3

# Suppress insecure request warnings for prototype
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from ..models import CollectedPart
from ..normalizer import normalize_text, parse_price_tnd, normalize_quality_level

def search_autopart(make: str, model: str, year: int, part_category: str) -> list:
    """
    Search AutoPart.tn for a given part and vehicle.
    Returns a list of CollectedPart objects.
    """
    query = f"{part_category} {make} {model}"
    url = "https://autopart.tn/recherche/"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
    }
    
    params = {
        "q": query
    }
    
    results = []
    
    try:
        response = requests.get(url, params=params, headers=headers, timeout=10, verify=False)
        
        if response.status_code != 200:
            print(f"AutoPart.tn returned status code {response.status_code}")
            return []
            
        soup = BeautifulSoup(response.text, "html.parser")
        
        # We don't know the exact selectors yet without deep inspection.
        # Let's try standard WooCommerce / general ecommerce selectors
        products = soup.select(".product, .item, .product-item, .ty-column3")
        
        # If the site blocks scraping or uses JavaScript rendering, products might be empty
        if not products:
            # Let's look for any generic links with the query words
            links = soup.find_all('a')
            valid_links = []
            for link in links:
                href = link.get('href', '')
                if 'produit' in href or 'product' in href or part_category.lower() in href.lower():
                    valid_links.append(link)
            
            # If nothing looks like a product, document it
            print("No clear product selectors found. The site may require JavaScript, have different selectors, or the search returned no results.")
            
        for product in products[:5]: # limit to 5 for now
            title_el = product.select_one(".product-title, .title, h2, h3, .name")
            price_el = product.select_one(".price, .amount, .ty-price-num")
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
                continue # Skip empty items
                
            part = CollectedPart(
                source="autopart",
                source_url=product_url,
                image_url=img_url,
                make=make,
                model=model,
                year=year,
                part_category=part_category,
                part_name=title,
                part_brand="N/A", # Hard to extract automatically without specific selectors
                reference="N/A",
                price_tnd=price_tnd,
                availability="N/A",
                condition="N/A",
                quality_level=normalize_quality_level(),
                collected_at=datetime.now().isoformat()
            )
            results.append(part)
            
    except requests.exceptions.RequestException as e:
        print(f"Error fetching from AutoPart.tn: {e}")
        
    return results
