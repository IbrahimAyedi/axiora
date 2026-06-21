import requests
from bs4 import BeautifulSoup
from datetime import datetime
import urllib3

# Suppress insecure request warnings for prototype
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from ..models import CollectedPart
from ..normalizer import normalize_text, parse_price_tnd, normalize_quality_level
from ..relevance import is_relevant_part

MAX_CATEGORY_PAGES = 6

def search_karhabtk(make: str, model: str, year: int, part_category: str) -> list:
    """
    Search Karhabtk.tn for a given part and vehicle.
    Returns a list of CollectedPart objects.
    """
    query = f"{part_category} {make} {model}"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
    }
    
    results = []
    
    try:
        target_url = None
        is_category_search = False
        
        if part_category.lower() == "phare":
            optique_url = "https://www.karhabtk.tn/15-optique"
            print(f"Karhabtk Optique category URL: {optique_url}")
            
            response = requests.get(optique_url, headers=headers, timeout=10, verify=False)
            if response.status_code == 200:
                soup = BeautifulSoup(response.text, "html.parser")
                
                # Find PHARE subcategory
                phare_link = None
                subcategories = soup.select(".subcategory-image a, .subcategory-name, .subcategories a, #subcategories a, a.subcategory-name")
                if not subcategories:
                    # Generic fallback if specific selectors don't work
                    subcategories = soup.find_all('a')
                    
                for a in subcategories:
                    text = a.text.strip().upper()
                    if text == "PHARE" or "PHARE" in text:
                        phare_link = a.get("href")
                        break
                        
                if phare_link:
                    if not phare_link.startswith("http"):
                        phare_link = "https://www.karhabtk.tn" + phare_link
                    print(f"Karhabtk Discovered PHARE subcategory URL: {phare_link}")
                    target_url = phare_link
                    is_category_search = True
                else:
                    print("Karhabtk Warning: Could not find PHARE subcategory link. Falling back to general search.")
            else:
                print(f"Karhabtk Warning: Optique page returned {response.status_code}. Falling back to general search.")

        if not target_url:
            # Fallback to general search
            target_url = "https://www.karhabtk.tn/recherche"
            is_category_search = False
            
        params = {
            "controller": "search",
            "s": query
        }
        
        total_raw_count = 0
        total_relevant_count = 0
        pages_scanned = 0
        
        for page in range(1, MAX_CATEGORY_PAGES + 1):
            if not is_category_search:
                params["page"] = page
                response = requests.get(target_url, params=params, headers=headers, timeout=10, verify=False)
                current_url = response.url
            else:
                if page == 1:
                    current_url = target_url
                else:
                    current_url = f"{target_url}?page={page}"
                response = requests.get(current_url, headers=headers, timeout=10, verify=False)
                
            if response.status_code != 200:
                print(f"Karhabtk returned status code {response.status_code} for {current_url}")
                break
                
            soup = BeautifulSoup(response.text, "html.parser")
            products = soup.select(".product-miniature, .item, .product-item, .ajax_block_product")
            raw_count = len(products)
            
            if raw_count == 0:
                print(f"Karhabtk: No products found on page {page}. Stopping pagination.")
                break
                
            pages_scanned += 1
            total_raw_count += raw_count
            relevant_on_page = 0
            
            for product in products:
                title_el = product.select_one(".product-title, .h3, h2, h3, .name")
                price_el = product.select_one(".price, .amount, .ty-price-num, .product-price")
                img_el = product.select_one("img")
                link_el = product.select_one("a")
                
                title = normalize_text(title_el.text) if title_el else "N/A"
                if title == "N/A" and link_el and link_el.text.strip():
                    title = normalize_text(link_el.text)
                    
                if title != "N/A":
                    # Check vehicle match
                    title_lower = title.lower()
                    model_lower = str(model).lower()
                    
                    if model_lower not in title_lower:
                        print(f"Skipping Karhabtk product '{title}': Does not match model {model}")
                        continue
                        
                    # Year matching
                    import re
                    years_in_title = re.findall(r'\b(19\d{2}|20\d{2})\b', title_lower)
                    target_year_str = str(year).lower()
                    
                    if target_year_str != "any":
                        if years_in_title and target_year_str not in years_in_title:
                            print(f"Skipping Karhabtk product '{title}': Year mismatch (found {years_in_title}, expected {year})")
                            continue
                            
                    relevant, reason = is_relevant_part(part_category, title)
                    if not relevant:
                        print(f"Skipping Karhabtk product '{title}': {reason}")
                        continue
                    
                price_text = price_el.text if price_el else "0"
                price_tnd = parse_price_tnd(price_text)
                
                img_url = img_el.get("src") or img_el.get("data-src") if img_el else "N/A"
                product_url = link_el.get("href") if link_el else "N/A"
                
                if title == "N/A" and price_tnd == 0.0:
                    continue
                    
                part = CollectedPart(
                    source="karhabtk",
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
                relevant_on_page += 1
                
            total_relevant_count += relevant_on_page
            print(f"Karhabtk page {page}: {raw_count} raw products, {relevant_on_page} relevant products")
            
            if relevant_on_page > 0:
                print("Karhabtk: Found relevant products. Stopping pagination early.")
                break
                
        print(f"Karhabtk pages scanned: {pages_scanned}")
        print(f"Karhabtk Total raw products: {total_raw_count}")
        print(f"Karhabtk Total relevant products: {total_relevant_count}")
            
    except requests.exceptions.RequestException as e:
        print(f"Error fetching from Karhabtk: {e}")
        
    return results

