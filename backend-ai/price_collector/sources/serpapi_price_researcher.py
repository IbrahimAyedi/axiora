"""
SerpAPI Price Researcher - Safe, cached price estimation using SerpAPI for PFA prototype.

This module provides approximate Tunisian spare-part price estimates using:
1. Local cache (30-day validity for prices, 7-day for no results)
2. SerpAPI Google Search API (requires SERPAPI_API_KEY)
3. Price extraction from search result titles/snippets

IMPORTANT: This is a PFA prototype module. Not designed for high-traffic production.
Expected usage: a few searches per day to save API quota.

Safety features:
- Cache-first approach (no unnecessary API calls)
- Non-crashing fallback if API key missing
- Request timeout (25 seconds) and error handling
- Sanity checks on extracted prices
- Single optimized query per vehicle/part to save quota
- API errors/timeouts NOT cached (allows retry)

Cache behavior:
- Success with prices: cached 30 days
- Success with no prices: cached 7 days
- API errors/timeouts: NOT cached (allows retry)
"""

import os
import csv
import re
import json
import statistics
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from urllib.parse import urlencode
import urllib.request
import urllib.error

# Project paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SERPAPI_CACHE_PATH = os.path.join(PROJECT_ROOT, 'data', 'serpapi_price_cache.csv')

# Cache validity
CACHE_VALIDITY_DAYS = 30
NEGATIVE_CACHE_VALIDITY_DAYS = 7

# API configuration (loaded from environment)
SERPAPI_API_KEY = os.environ.get('SERPAPI_API_KEY')

# Request timeout
REQUEST_TIMEOUT = 25  # seconds (increased for reliability)

# Tunisian domain/keyword indicators
TUNISIAN_INDICATORS = [
    '.tn',
    'karhabtk',
    'ballouchi',
    'tunisie-annonce',
    'tayara',
    'autopart',
    'piecesautos',
    'sosautoparts',
    'monautopieces',
    'sauto',
    'tunisie',
    'tunis'
]

# Part category-specific sanity ranges (TND)
SANITY_RANGES = {
    'phare': {'min': 100, 'max': 3000},
    'feu': {'min': 100, 'max': 3000},
    'pneu': {'min': 80, 'max': 1500},
    'pare-brise': {'min': 150, 'max': 5000},
    'vitre': {'min': 50, 'max': 2000},
    'pare-chocs': {'min': 100, 'max': 4000},
    'default': {'min': 50, 'max': 5000}
}


def generate_optimized_query(make: str, model: str, year: int, part_category: str) -> str:
    """
    Generate a single optimized search query for Tunisian spare part prices.
    Uses OR operators to combine synonyms and save API quota.
    
    Args:
        make: Vehicle make (e.g., "Peugeot")
        model: Vehicle model (e.g., "208")
        year: Vehicle year (e.g., 2018)
        part_category: Part category (e.g., "phare")
    
    Returns:
        Single optimized query string
    """
    # French keywords for common parts
    part_keywords = {
        'phare': 'phare OR optique OR "feu avant"',
        'feu': 'feu OR phare OR optique',
        'pneu': 'pneu OR pneumatique',
        'pare-brise': '"pare-brise" OR "vitre avant"',
        'vitre': 'vitre OR glace',
        'pare-chocs': '"pare-chocs" OR bouclier'
    }
    
    keywords = part_keywords.get(part_category, part_category)
    
    # Include year if it looks valid
    year_str = ""
    if year and str(year).isdigit() and 1980 <= int(year) <= 2030:
        year_str = f" {year}"
    
    # Single optimized query with OR operators
    query = f"{keywords} {make} {model}{year_str} prix Tunisie"
    
    return query


def load_serpapi_cache() -> List[Dict]:
    """Load SerpAPI price cache from CSV file."""
    if not os.path.exists(SERPAPI_CACHE_PATH):
        return []
    
    try:
        with open(SERPAPI_CACHE_PATH, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            return list(reader)
    except Exception as e:
        print(f"Warning: Failed to load SerpAPI cache: {e}")
        return []


def save_to_serpapi_cache(cache_entry: Dict) -> None:
    """
    Save a price research result to SerpAPI cache.
    
    Args:
        cache_entry: Dictionary with cache fields
    """
    file_exists = os.path.exists(SERPAPI_CACHE_PATH)
    
    # Ensure data directory exists
    os.makedirs(os.path.dirname(SERPAPI_CACHE_PATH), exist_ok=True)
    
    fieldnames = [
        'make', 'model', 'year', 'part_category', 'query',
        'min_price_tnd', 'median_price_tnd', 'max_price_tnd',
        'confidence', 'sources_json', 'created_at', 'expires_at'
    ]
    
    try:
        with open(SERPAPI_CACHE_PATH, 'a', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if not file_exists:
                writer.writeheader()
            writer.writerow(cache_entry)
    except Exception as e:
        print(f"Warning: Failed to save to SerpAPI cache: {e}")


def check_serpapi_cache(make: str, model: str, year: int, part_category: str) -> Optional[Dict]:
    """
    Check if a valid cached result exists in SerpAPI cache.
    
    Args:
        make: Vehicle make
        model: Vehicle model
        year: Vehicle year
        part_category: Part category
    
    Returns:
        Cached result dict or None if not found/expired
    """
    cache = load_serpapi_cache()
    now = datetime.now()
    
    for entry in cache:
        # Match by make, model, year, part_category
        if (entry.get('make', '').lower() == str(make).lower() and
            entry.get('model', '').lower() == str(model).lower() and
            entry.get('year', '') == str(year) and
            entry.get('part_category', '').lower() == str(part_category).lower()):
            
            # Check expiration
            expires_at_str = entry.get('expires_at', '')
            if expires_at_str:
                try:
                    expires_at = datetime.fromisoformat(expires_at_str)
                    if now < expires_at:
                        # Valid cache hit
                        return {
                            'status': 'cache_hit',
                            'cache_hit': True,
                            'query': entry.get('query', ''),
                            'min_price_tnd': float(entry.get('min_price_tnd', 0)),
                            'median_price_tnd': float(entry.get('median_price_tnd', 0)),
                            'max_price_tnd': float(entry.get('max_price_tnd', 0)),
                            'confidence': entry.get('confidence', 'low'),
                            'sources': json.loads(entry.get('sources_json', '[]')),
                            'cached_at': entry.get('created_at', ''),
                            'expires_at': expires_at_str,
                            'warnings': ['Using cached SerpAPI result']
                        }
                except (ValueError, TypeError):
                    continue
    
    return None


def extract_prices_from_text(text: str, part_category: str) -> List[float]:
    """
    Extract price values from text (title, snippet, etc).
    
    Recognizes patterns like:
    - 450 TND
    - 450 DT
    - 450 د.ت
    - Prix 450
    - 1 250 TND (with space separator)
    - 324,200 TND (with comma)
    
    Args:
        text: Text to extract prices from
        part_category: Part category for sanity checking
    
    Returns:
        List of valid price floats
    """
    if not text:
        return []
    
    prices = []
    
    # Patterns to match prices
    patterns = [
        r'(\d[\d\s,]*)\s*(?:TND|DT|د\.ت|dinar)',  # 450 TND, 1 250 TND
        r'(?:prix|price|cout|coût|à)\s*:?\s*(\d[\d\s,]*)',  # Prix: 450
    ]
    
    for pattern in patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            price_str = match.group(1)
            
            # Clean up: remove spaces and commas
            price_str = price_str.replace(' ', '').replace(',', '')
            
            try:
                price = float(price_str)
                
                # Apply sanity checks
                sanity = SANITY_RANGES.get(part_category, SANITY_RANGES['default'])
                if sanity['min'] <= price <= sanity['max']:
                    prices.append(price)
            except ValueError:
                continue
    
    return prices


def score_source_relevance(url: str, title: str, snippet: str) -> float:
    """
    Score how relevant/trustworthy a source is for Tunisian prices.
    
    Returns score between 0.0 and 1.0
    """
    score = 0.0
    text_combined = (url + ' ' + title + ' ' + snippet).lower()
    
    # Check for Tunisian indicators
    for indicator in TUNISIAN_INDICATORS:
        if indicator.lower() in text_combined:
            score += 0.3
    
    # Prefer known auto parts sites
    if any(site in text_combined for site in ['karhabtk', 'ballouchi', 'autopart', 'piecesautos']):
        score += 0.4
    
    # Cap at 1.0
    return min(score, 1.0)


def perform_serpapi_search(query: str) -> Optional[Dict]:
    """
    Perform SerpAPI Google Search API request.
    
    Args:
        query: Search query string
    
    Returns:
        Search results dict or None on error
    """
    if not SERPAPI_API_KEY:
        return None
    
    params = {
        'api_key': SERPAPI_API_KEY,
        'q': query,
        'engine': 'google',
        'num': 10,  # Get 10 results per query
        'gl': 'tn',  # Geographic location: Tunisia
        'hl': 'fr',  # Language: French
    }
    
    url = 'https://serpapi.com/search?' + urlencode(params)
    
    try:
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0 (PFA Prototype SerpAPI Researcher)')
        
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data
    except urllib.error.HTTPError as e:
        print(f"Warning: SerpAPI HTTP error: {e.code} - {e.reason}")
        try:
            error_body = e.read().decode('utf-8')
            print(f"SerpAPI error details: {error_body}")
        except:
            pass
        return None
    except urllib.error.URLError as e:
        print(f"Warning: SerpAPI connection error: {e.reason}")
        return None
    except Exception as e:
        print(f"Warning: SerpAPI error: {e}")
        return None


def research_serpapi_prices(make: str, model: str, year: int, part_category: str) -> Dict:
    """
    Research web prices using SerpAPI with caching and safe fallback.
    
    Priority:
    1. Check cache first (30-day validity)
    2. If no cache, perform SerpAPI search (if API key available)
    3. Extract prices from results
    4. Cache result
    
    Args:
        make: Vehicle make (e.g., "Peugeot")
        model: Vehicle model (e.g., "208")
        year: Vehicle year (e.g., 2018)
        part_category: Part category (e.g., "phare")
    
    Returns:
        Dictionary with:
        - status: 'cache_hit' | 'serpapi_success' | 'serpapi_key_missing' | 'no_prices_found'
        - cache_hit: bool
        - query: generated query string
        - min_price_tnd: float
        - median_price_tnd: float
        - max_price_tnd: float
        - confidence: 'low' | 'medium' | 'high'
        - sources: list of source dicts
        - warnings: list of warning strings
    """
    # Step 1: Check cache
    cached_result = check_serpapi_cache(make, model, year, part_category)
    if cached_result:
        return cached_result
    
    # Step 2: Generate optimized query
    query = generate_optimized_query(make, model, year, part_category)
    print(f"Generated SerpAPI query: {query}")
    
    # Step 3: Check if API is configured
    if not SERPAPI_API_KEY:
        return {
            'status': 'serpapi_key_missing',
            'cache_hit': False,
            'query': query,
            'min_price_tnd': 0.0,
            'median_price_tnd': 0.0,
            'max_price_tnd': 0.0,
            'confidence': 'low',
            'sources': [],
            'warnings': [
                'SERPAPI_API_KEY environment variable not configured.',
                'Set SERPAPI_API_KEY to enable SerpAPI price research.',
                'Example: export SERPAPI_API_KEY=your_key_here'
            ]
        }
    
    # Step 4: Perform SerpAPI search
    result = perform_serpapi_search(query)
    if not result:
        # API call failed - DO NOT CACHE errors/timeouts
        # Return error status without caching to allow retry on next attempt
        return {
            'status': 'serpapi_api_error',
            'cache_hit': False,
            'query': query,
            'min_price_tnd': 0.0,
            'median_price_tnd': 0.0,
            'max_price_tnd': 0.0,
            'confidence': 'low',
            'sources': [],
            'warnings': [
                'SerpAPI request failed (timeout, HTTP error, or network issue).',
                'Not cached - will retry on next request.',
                'If this persists, check API key validity, quota, or network connection.'
            ]
        }
    
    # Step 5: Extract prices from organic results
    all_prices = []
    sources = []
    
    organic_results = result.get('organic_results', [])
    
    for item in organic_results:
        title = item.get('title', '')
        snippet = item.get('snippet', '')
        link = item.get('link', '')
        
        # Extract prices from title and snippet
        prices_from_title = extract_prices_from_text(title, part_category)
        prices_from_snippet = extract_prices_from_text(snippet, part_category)
        
        # Check for rich snippet prices
        rich_snippet = item.get('rich_snippet', {})
        prices_from_rich = []
        if rich_snippet:
            rich_text = str(rich_snippet)
            prices_from_rich = extract_prices_from_text(rich_text, part_category)
        
        item_prices = prices_from_title + prices_from_snippet + prices_from_rich
        
        if item_prices or link:  # Include source even if no price found (for debugging)
            relevance_score = score_source_relevance(link, title, snippet)
            
            # Extract domain
            try:
                from urllib.parse import urlparse
                domain = urlparse(link).netloc
            except:
                domain = link[:50]
            
            sources.append({
                'title': title[:100],  # Truncate long titles
                'link': link,
                'snippet': snippet[:150],  # Truncate long snippets
                'prices_found': item_prices,
                'source_domain': domain,
                'relevance_score': relevance_score
            })
            
            # Add prices to overall list
            all_prices.extend(item_prices)
    
    # Step 6: Compute statistics
    if not all_prices:
        # No prices found - cache negative result
        now = datetime.now()
        expires_at = now + timedelta(days=NEGATIVE_CACHE_VALIDITY_DAYS)
        
        cache_entry = {
            'make': make,
            'model': model,
            'year': year,
            'part_category': part_category,
            'query': query,
            'min_price_tnd': 0.0,
            'median_price_tnd': 0.0,
            'max_price_tnd': 0.0,
            'confidence': 'low',
            'sources_json': json.dumps([{'title': s['title'], 'domain': s['source_domain'], 'relevance': s['relevance_score']} for s in sources[:5]]),
            'created_at': now.isoformat(),
            'expires_at': expires_at.isoformat()
        }
        save_to_serpapi_cache(cache_entry)
        
        warnings = [
            f'No valid prices found for {make} {model} {part_category}.',
            f'Searched {len(sources)} sources but no prices matched sanity rules.'
        ]
        
        # Add sanity range info
        sanity = SANITY_RANGES.get(part_category, SANITY_RANGES['default'])
        warnings.append(f"Expected price range: {sanity['min']}-{sanity['max']} TND")
        
        return {
            'status': 'no_prices_found',
            'cache_hit': False,
            'query': query,
            'min_price_tnd': 0.0,
            'median_price_tnd': 0.0,
            'max_price_tnd': 0.0,
            'confidence': 'low',
            'sources': sources,
            'warnings': warnings
        }
    
    # Remove duplicates and sort
    unique_prices = sorted(set(all_prices))
    
    min_price = min(unique_prices)
    max_price = max(unique_prices)
    median_price = statistics.median(unique_prices)
    
    # Step 7: Determine confidence
    confidence = 'low'
    tunisian_sources_count = sum(1 for s in sources if s.get('relevance_score', 0) > 0.3)
    price_sources_count = sum(1 for s in sources if s.get('prices_found'))
    
    warnings = []
    
    if len(unique_prices) >= 3 and tunisian_sources_count >= 2:
        confidence = 'high'
    elif len(unique_prices) >= 2 and tunisian_sources_count >= 1:
        confidence = 'medium'
    else:
        warnings.append('Low confidence: few prices or non-Tunisian sources')
    
    if len(unique_prices) == 1:
        warnings.append('Only one unique price found - confidence limited')
    
    if tunisian_sources_count == 0:
        warnings.append('No clearly Tunisian sources found - prices may not reflect Tunisian market')
    
    # Step 8: Cache the result
    now = datetime.now()
    expires_at = now + timedelta(days=CACHE_VALIDITY_DAYS)
    
    # Prepare sources for JSON storage (limit to top 5 most relevant)
    sources_sorted = sorted(sources, key=lambda x: x.get('relevance_score', 0), reverse=True)
    sources_for_cache = [
        {'title': s['title'], 'domain': s.get('source_domain', ''), 'relevance': s.get('relevance_score', 0)}
        for s in sources_sorted[:5]
    ]
    
    cache_entry = {
        'make': make,
        'model': model,
        'year': year,
        'part_category': part_category,
        'query': query,
        'min_price_tnd': round(min_price, 2),
        'median_price_tnd': round(median_price, 2),
        'max_price_tnd': round(max_price, 2),
        'confidence': confidence,
        'sources_json': json.dumps(sources_for_cache),
        'created_at': now.isoformat(),
        'expires_at': expires_at.isoformat()
    }
    save_to_serpapi_cache(cache_entry)
    
    return {
        'status': 'serpapi_success',
        'cache_hit': False,
        'query': query,
        'min_price_tnd': round(min_price, 2),
        'median_price_tnd': round(median_price, 2),
        'max_price_tnd': round(max_price, 2),
        'confidence': confidence,
        'sources': sources_sorted[:10],  # Return top 10 for inspection
        'warnings': warnings
    }
