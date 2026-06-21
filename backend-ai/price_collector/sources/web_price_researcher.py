"""
Web Price Researcher - Safe, cached price estimation fallback for PFA prototype.

This module provides approximate Tunisian spare-part price estimates using:
1. Local cache (30-day validity)
2. Optional Google Custom Search JSON API (requires API keys)
3. Price extraction from search result titles/snippets

IMPORTANT: This is a PFA prototype module. Not designed for high-traffic production.
Expected usage: a few searches per day.

Safety features:
- Cache-first approach (no unnecessary API calls)
- Non-crashing fallback if API keys missing
- Request timeout and error handling
- Sanity checks on extracted prices
"""

import os
import csv
import re
import json
import statistics
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlencode
import urllib.request
import urllib.error

# Project paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CACHE_PATH = os.path.join(PROJECT_ROOT, 'data', 'web_price_cache.csv')

# Cache validity
CACHE_VALIDITY_DAYS = 30
NEGATIVE_CACHE_VALIDITY_DAYS = 7

# API configuration (loaded from environment)
GOOGLE_API_KEY = os.environ.get('GOOGLE_CUSTOM_SEARCH_API_KEY')
GOOGLE_CSE_ID = os.environ.get('GOOGLE_CUSTOM_SEARCH_ENGINE_ID')

# Request timeout
REQUEST_TIMEOUT = 10  # seconds

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
    'phare': {'min': 30, 'max': 3000},
    'feu': {'min': 30, 'max': 3000},
    'pneu': {'min': 80, 'max': 1500},
    'pare-brise': {'min': 150, 'max': 5000},
    'vitre': {'min': 50, 'max': 2000},
    'pare-chocs': {'min': 100, 'max': 4000},
    'default': {'min': 50, 'max': 5000}
}


def generate_search_queries(make: str, model: str, year: int, part_category: str) -> List[str]:
    """
    Generate search queries for Tunisian spare part prices.
    
    Args:
        make: Vehicle make (e.g., "Peugeot")
        model: Vehicle model (e.g., "208")
        year: Vehicle year (e.g., 2018)
        part_category: Part category (e.g., "phare")
    
    Returns:
        List of search query strings
    """
    queries = []
    
    # French keywords for common parts
    part_keywords = {
        'phare': ['phare', 'optique', 'feu avant'],
        'feu': ['feu', 'phare', 'optique'],
        'pneu': ['pneu', 'pneumatique'],
        'pare-brise': ['pare-brise', 'vitre avant'],
        'vitre': ['vitre', 'glace'],
        'pare-chocs': ['pare-chocs', 'bouclier']
    }
    
    keywords = part_keywords.get(part_category, [part_category])
    
    for keyword in keywords:
        # Include year if it looks valid
        if year and str(year).isdigit() and 1980 <= int(year) <= 2030:
            query = f"{keyword} {make} {model} {year} prix Tunisie"
        else:
            query = f"{keyword} {make} {model} prix Tunisie"
        queries.append(query)
    
    # Add a more specific query without "prix"
    queries.append(f"{make} {model} {part_category} Tunisie")
    
    return queries[:3]  # Limit to 3 queries to reduce API usage


def load_cache() -> List[Dict]:
    """Load price cache from CSV file."""
    if not os.path.exists(CACHE_PATH):
        return []
    
    try:
        with open(CACHE_PATH, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            return list(reader)
    except Exception as e:
        print(f"Warning: Failed to load cache: {e}")
        return []


def save_to_cache(cache_entry: Dict) -> None:
    """
    Save a price research result to cache.
    
    Args:
        cache_entry: Dictionary with cache fields
    """
    file_exists = os.path.exists(CACHE_PATH)
    
    # Ensure data directory exists
    os.makedirs(os.path.dirname(CACHE_PATH), exist_ok=True)
    
    fieldnames = [
        'make', 'model', 'year', 'part_category', 'query',
        'min_price_tnd', 'median_price_tnd', 'max_price_tnd',
        'confidence', 'sources_json', 'created_at', 'expires_at'
    ]
    
    try:
        with open(CACHE_PATH, 'a', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if not file_exists:
                writer.writeheader()
            writer.writerow(cache_entry)
    except Exception as e:
        print(f"Warning: Failed to save to cache: {e}")


def check_cache(make: str, model: str, year: int, part_category: str) -> Optional[Dict]:
    """
    Check if a valid cached result exists.
    
    Args:
        make: Vehicle make
        model: Vehicle model
        year: Vehicle year
        part_category: Part category
    
    Returns:
        Cached result dict or None if not found/expired
    """
    cache = load_cache()
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
                            'min_price_tnd': float(entry.get('min_price_tnd', 0)),
                            'median_price_tnd': float(entry.get('median_price_tnd', 0)),
                            'max_price_tnd': float(entry.get('max_price_tnd', 0)),
                            'confidence': entry.get('confidence', 'low'),
                            'sources': json.loads(entry.get('sources_json', '[]')),
                            'cached_at': entry.get('created_at', ''),
                            'expires_at': expires_at_str,
                            'warnings': ['Using cached web research result']
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
        r'(\d[\d\s,]+)\s*(?:euro|eur|€)',  # Convert EUR to TND roughly (not ideal but fallback)
    ]
    
    for pattern in patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            price_str = match.group(1)
            
            # Clean up: remove spaces and commas
            price_str = price_str.replace(' ', '').replace(',', '')
            
            try:
                price = float(price_str)
                
                # If it was in EUR, convert roughly (1 EUR ≈ 3.3 TND, very approximate)
                if 'euro' in match.group(0).lower() or 'eur' in match.group(0).lower():
                    price = price * 3.3
                
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


def perform_google_search(query: str) -> Optional[Dict]:
    """
    Perform Google Custom Search API request.
    
    Args:
        query: Search query string
    
    Returns:
        Search results dict or None on error
    """
    if not GOOGLE_API_KEY or not GOOGLE_CSE_ID:
        return None
    
    params = {
        'key': GOOGLE_API_KEY,
        'cx': GOOGLE_CSE_ID,
        'q': query,
        'num': 5,  # Get 5 results per query
        'gl': 'tn',  # Geographic location: Tunisia
        'lr': 'lang_fr',  # Language: French
    }
    
    url = 'https://www.googleapis.com/customsearch/v1?' + urlencode(params)
    
    try:
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0 (PFA Prototype Price Researcher)')
        
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data
    except urllib.error.HTTPError as e:
        print(f"Warning: Google Search API HTTP error: {e.code} - {e.reason}")
        return None
    except urllib.error.URLError as e:
        print(f"Warning: Google Search API connection error: {e.reason}")
        return None
    except Exception as e:
        print(f"Warning: Google Search API error: {e}")
        return None


def research_web_prices(make: str, model: str, year: int, part_category: str) -> Dict:
    """
    Research web prices for a spare part with caching and safe fallback.
    
    Priority:
    1. Check cache first (30-day validity)
    2. If no cache, perform web search (if API keys available)
    3. Extract prices from results
    4. Cache result
    
    Args:
        make: Vehicle make (e.g., "Peugeot")
        model: Vehicle model (e.g., "208")
        year: Vehicle year (e.g., 2018)
        part_category: Part category (e.g., "phare")
    
    Returns:
        Dictionary with:
        - status: 'cache_hit' | 'api_success' | 'manual_search_required' | 'no_prices_found'
        - cache_hit: bool
        - generated_queries: list of query strings
        - min_price_tnd: float
        - median_price_tnd: float
        - max_price_tnd: float
        - confidence: 'low' | 'medium' | 'high'
        - sources: list of source dicts
        - warnings: list of warning strings
    """
    # Step 1: Check cache
    cached_result = check_cache(make, model, year, part_category)
    if cached_result:
        queries = generate_search_queries(make, model, year, part_category)
        cached_result['generated_queries'] = queries
        return cached_result
    
    # Step 2: Generate search queries
    queries = generate_search_queries(make, model, year, part_category)
    
    # Step 3: Check if API is configured
    if not GOOGLE_API_KEY or not GOOGLE_CSE_ID:
        return {
            'status': 'manual_search_required',
            'cache_hit': False,
            'generated_queries': queries,
            'min_price_tnd': 0.0,
            'median_price_tnd': 0.0,
            'max_price_tnd': 0.0,
            'confidence': 'low',
            'sources': [],
            'warnings': [
                'Google Custom Search API keys not configured.',
                'Set GOOGLE_CUSTOM_SEARCH_API_KEY and GOOGLE_CUSTOM_SEARCH_ENGINE_ID environment variables.',
                'Manual web search recommended.'
            ]
        }
    
    # Step 4: Perform web searches
    all_prices = []
    sources = []
    
    for query in queries:
        result = perform_google_search(query)
        if not result or 'items' not in result:
            continue
        
        for item in result.get('items', []):
            title = item.get('title', '')
            snippet = item.get('snippet', '')
            link = item.get('link', '')
            
            # Extract prices from title and snippet
            prices_from_title = extract_prices_from_text(title, part_category)
            prices_from_snippet = extract_prices_from_text(snippet, part_category)
            
            item_prices = prices_from_title + prices_from_snippet
            
            if item_prices:
                relevance_score = score_source_relevance(link, title, snippet)
                
                sources.append({
                    'url': link,
                    'title': title[:100],  # Truncate long titles
                    'prices_found': item_prices,
                    'relevance_score': relevance_score
                })
                
                # Add prices to overall list
                all_prices.extend(item_prices)
    
    # Step 5: Compute statistics
    if not all_prices:
        # No prices found - cache negative result
        now = datetime.now()
        expires_at = now + timedelta(days=NEGATIVE_CACHE_VALIDITY_DAYS)
        
        cache_entry = {
            'make': make,
            'model': model,
            'year': year,
            'part_category': part_category,
            'query': queries[0] if queries else '',
            'min_price_tnd': 0.0,
            'median_price_tnd': 0.0,
            'max_price_tnd': 0.0,
            'confidence': 'low',
            'sources_json': json.dumps([]),
            'created_at': now.isoformat(),
            'expires_at': expires_at.isoformat()
        }
        save_to_cache(cache_entry)
        
        return {
            'status': 'no_prices_found',
            'cache_hit': False,
            'generated_queries': queries,
            'min_price_tnd': 0.0,
            'median_price_tnd': 0.0,
            'max_price_tnd': 0.0,
            'confidence': 'low',
            'sources': sources,
            'warnings': [
                f'No valid prices found for {make} {model} {part_category}.',
                'Try manual web search or use alternative pricing method.'
            ]
        }
    
    # Remove duplicates and sort
    unique_prices = sorted(set(all_prices))
    
    min_price = min(unique_prices)
    max_price = max(unique_prices)
    median_price = statistics.median(unique_prices)
    
    # Step 6: Determine confidence
    confidence = 'low'
    tunisian_sources_count = sum(1 for s in sources if s.get('relevance_score', 0) > 0.3)
    
    if len(unique_prices) >= 3 and tunisian_sources_count >= 2:
        confidence = 'high'
    elif len(unique_prices) >= 2 and tunisian_sources_count >= 1:
        confidence = 'medium'
    
    # Step 7: Cache the result
    now = datetime.now()
    expires_at = now + timedelta(days=CACHE_VALIDITY_DAYS)
    
    # Prepare sources for JSON storage (limit to top 5 most relevant)
    sources_sorted = sorted(sources, key=lambda x: x.get('relevance_score', 0), reverse=True)
    sources_for_cache = [
        {'url': s['url'], 'title': s['title'], 'relevance': s.get('relevance_score', 0)}
        for s in sources_sorted[:5]
    ]
    
    cache_entry = {
        'make': make,
        'model': model,
        'year': year,
        'part_category': part_category,
        'query': queries[0],
        'min_price_tnd': round(min_price, 2),
        'median_price_tnd': round(median_price, 2),
        'max_price_tnd': round(max_price, 2),
        'confidence': confidence,
        'sources_json': json.dumps(sources_for_cache),
        'created_at': now.isoformat(),
        'expires_at': expires_at.isoformat()
    }
    save_to_cache(cache_entry)
    
    return {
        'status': 'api_success',
        'cache_hit': False,
        'generated_queries': queries,
        'min_price_tnd': round(min_price, 2),
        'median_price_tnd': round(median_price, 2),
        'max_price_tnd': round(max_price, 2),
        'confidence': confidence,
        'sources': sources_sorted[:10],  # Return top 10 for inspection
        'warnings': [] if confidence != 'low' else ['Low confidence in price estimates. Consider manual verification.']
    }
