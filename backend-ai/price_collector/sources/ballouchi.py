import requests
from bs4 import BeautifulSoup
from datetime import datetime
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from ..models import CollectedPart
from ..normalizer import normalize_text, parse_price_tnd
from ..relevance import is_relevant_part

def search_ballouchi(make: str, model: str, year: int, part_category: str) -> list:
    """
    Search Ballouchi.com for a given part and vehicle.
    Returns a list of CollectedPart objects.
    Condition is forced to 'occasion' and quality_level to 'bas' or 'unknown'.
    """
    query = f"{part_category} {make} {model}"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
    }
    
    results = []
    
    # Potential search URLs for Ballouchi
    search_urls = [
        "https://www.ballouchi.com/annonces",
        "https://www.ballouchi.com/recherche"
    ]
    
    params = {
        "q": query
    }
    
    success_html = None
    target_url = None
    
    try:
        # Try a few endpoints
        for base_url in search_urls:
            print(f"Ballouchi: Trying {base_url} with query '{query}'")
            response = requests.get(base_url, params=params, headers=headers, timeout=10, verify=False)
            print(f"Ballouchi: Received status code {response.status_code} for {response.url}")
            
            if response.status_code == 200:
                success_html = response.text
                target_url = response.url
                break
                
        if not success_html:
            print("Ballouchi Warning: Could not get a successful 200 response from search endpoints.")
            return results
            
        soup = BeautifulSoup(success_html, "html.parser")
        
        # Ballouchi classes might vary, we will try common ones
        products = soup.select(".item, .ad, .annonce, article, .listing-item, .card")
        raw_count = len(products)
        
        print(f"Ballouchi: Found {raw_count} raw products on page.")
        
        if raw_count == 0:
            print("Ballouchi Warning: HTML structure parsed, but no recognizable product selectors found. The site may require JS, use different selectors, or the search returned no results.")
            return results
            
        relevant_count = 0
        
        for product in products:
            title_el = product.select_one("h2, h3, a.title, a.ad-title, .titre, .title")
            price_el = product.select_one(".price, .prix, .amount")
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
                    print(f"Skipping Ballouchi listing '{title}': Does not match model {model}")
                    continue
                    
                # Year matching
                import re
                years_in_title = re.findall(r'\b(19\d{2}|20\d{2})\b', title_lower)
                target_year_str = str(year).lower()
                
                if target_year_str != "any":
                    if years_in_title and target_year_str not in years_in_title:
                        print(f"Skipping Ballouchi listing '{title}': Year mismatch (found {years_in_title}, expected {year})")
                        continue
                        
                relevant, reason = is_relevant_part(part_category, title)
                if not relevant:
                    print(f"Skipping Ballouchi listing '{title}': {reason}")
                    continue
                
            price_text = price_el.text if price_el else "0"
            price_tnd = parse_price_tnd(price_text)
            
            img_url = img_el.get("src") or img_el.get("data-src") if img_el else "N/A"
            product_url = link_el.get("href") if link_el else "N/A"
            
            if product_url != "N/A" and not product_url.startswith("http"):
                product_url = "https://www.ballouchi.com" + product_url if product_url.startswith("/") else "https://www.ballouchi.com/" + product_url
                
            if title == "N/A" and price_tnd == 0.0:
                continue
                
            part = CollectedPart(
                source="ballouchi",
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
                condition="occasion",      # Forced to occasion as per requirements
                quality_level="unknown",   # or 'bas'
                collected_at=datetime.now().isoformat()
            )
            results.append(part)
            relevant_count += 1
            
        print(f"Ballouchi Total relevant products: {relevant_count}")
        
    except requests.exceptions.RequestException as e:
        print(f"Error fetching from Ballouchi: {e}")
        
    return results
