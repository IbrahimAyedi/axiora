# SerpAPI Price Researcher - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    USER / TEST SCRIPT                                │
│                                                                       │
│  test_serpapi_price_researcher.py                                    │
│  └─ Test Cases:                                                      │
│     • Peugeot 208 + phare                                            │
│     • Renault Symbol 2017 + phare                                    │
│     • Peugeot 208 + pneu                                             │
│     • Cache verification test                                        │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ research_serpapi_prices(make, model, year, part)
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│              SERPAPI PRICE RESEARCHER MODULE                         │
│                                                                       │
│  price_collector/sources/serpapi_price_researcher.py                 │
│                                                                       │
│  Main Function: research_serpapi_prices()                            │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 1: CHECK CACHE FIRST                                     │ │
│  │  └─ check_serpapi_cache(make, model, year, part_category)     │ │
│  │     • Load data/serpapi_price_cache.csv                        │ │
│  │     • Match by make/model/year/part_category                   │ │
│  │     • Check expiration (30 days for prices, 7 for no-results)  │ │
│  │     • If valid cache → return immediately (no API call)        │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 │ if no cache                         │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 2: GENERATE OPTIMIZED QUERY                              │ │
│  │  └─ generate_optimized_query(make, model, year, part_category)│ │
│  │     • Use OR operators for synonyms                            │ │
│  │     • Example: "phare OR optique OR feu avant"                 │ │
│  │     • Add vehicle: "Peugeot 208 2018"                          │ │
│  │     • Add location: "prix Tunisie"                             │ │
│  │     • Single query to save quota                               │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 3: CHECK API KEY                                         │ │
│  │  └─ if not SERPAPI_API_KEY:                                    │ │
│  │       return status='serpapi_key_missing' (safe fallback)      │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 │ if key exists                       │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 4: CALL SERPAPI                                          │ │
│  │  └─ perform_serpapi_search(query)                              │ │
│  │     • Endpoint: https://serpapi.com/search                     │ │
│  │     • Params: engine=google, gl=tn, hl=fr, num=10             │ │
│  │     • Timeout: 10 seconds                                      │ │
│  │     • Error handling: HTTP errors, timeouts, JSON parse        │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 │ organic_results                     │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 5: EXTRACT PRICES                                        │ │
│  │  └─ extract_prices_from_text(title + snippet, part_category)  │ │
│  │     • Regex patterns: 450 TND, 450 DT, Prix 450                │ │
│  │     • Sanity check: phare 100-3000 TND, pneu 80-1500 TND       │ │
│  │     • Reject invalid prices (0, 20 TND for headlight)          │ │
│  │     • Convert to float TND                                     │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 │ valid_prices                        │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 6: SCORE SOURCES                                         │ │
│  │  └─ score_source_relevance(url, title, snippet)               │ │
│  │     • Check for .tn, karhabtk, ballouchi, tunisie              │ │
│  │     • +0.3 per Tunisian indicator                              │ │
│  │     • +0.4 for known auto parts sites                          │ │
│  │     • Max score: 1.0                                           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 │ sources with scores                 │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 7: CALCULATE CONFIDENCE                                  │ │
│  │  └─ Based on:                                                  │ │
│  │     • Number of unique prices (3+ → better)                    │ │
│  │     • Number of Tunisian sources (2+ → better)                 │ │
│  │     • High: 3+ prices, 2+ Tunisian sources                     │ │
│  │     • Medium: 1-2 prices, 1+ Tunisian sources                  │ │
│  │     • Low: no prices or weak sources                           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 │ min, median, max prices             │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 8: SAVE TO CACHE                                         │ │
│  │  └─ save_to_serpapi_cache(cache_entry)                         │ │
│  │     • Write to data/serpapi_price_cache.csv                    │ │
│  │     • Set expires_at (30 days or 7 days)                       │ │
│  │     • Store sources_json (top 5 most relevant)                 │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                 │                                     │
│                                 │ result dict                         │
│                                 ▼                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  STEP 9: RETURN RESULT                                         │ │
│  │  └─ {                                                          │ │
│  │       'status': 'serpapi_success' | 'cache_hit' | ...          │ │
│  │       'cache_hit': bool,                                       │ │
│  │       'query': str,                                            │ │
│  │       'min_price_tnd': float,                                  │ │
│  │       'median_price_tnd': float,                               │ │
│  │       'max_price_tnd': float,                                  │ │
│  │       'confidence': 'high' | 'medium' | 'low',                 │ │
│  │       'sources': [list of dicts],                              │ │
│  │       'warnings': [list of strings]                            │ │
│  │     }                                                          │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ result
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         EXTERNAL SERVICES                            │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  SERPAPI                                                       │ │
│  │  https://serpapi.com/search                                    │ │
│  │                                                                │ │
│  │  • Requires: SERPAPI_API_KEY                                   │ │
│  │  • Free tier: 100 searches/month                               │ │
│  │  • Returns: Google search results (organic)                    │ │
│  │  • Protected by cache (30-day validity)                        │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Google search results
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA STORAGE                                 │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  data/serpapi_price_cache.csv                                  │ │
│  │                                                                │ │
│  │  Columns:                                                      │ │
│  │  • make, model, year, part_category                            │ │
│  │  • query                                                       │ │
│  │  • min_price_tnd, median_price_tnd, max_price_tnd             │ │
│  │  • confidence                                                  │ │
│  │  • sources_json                                                │ │
│  │  • created_at, expires_at                                      │ │
│  │                                                                │ │
│  │  Validity:                                                     │ │
│  │  • 30 days for results with prices                             │ │
│  │  • 7 days for no-price results                                 │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Example

### Test Case: Peugeot 208 + phare

```
1. USER
   └─ research_serpapi_prices("Peugeot", "208", 2018, "phare")

2. CHECK CACHE
   └─ data/serpapi_price_cache.csv
      • No match found (first run)

3. GENERATE QUERY
   └─ "phare OR optique OR feu avant Peugeot 208 2018 prix Tunisie"

4. CHECK API KEY
   └─ SERPAPI_API_KEY not set
      • Return: status='serpapi_key_missing'
      • Safe fallback (no crash)

5. RETURN RESULT
   └─ {
        'status': 'serpapi_key_missing',
        'cache_hit': False,
        'query': 'phare OR optique OR "feu avant" Peugeot 208 2018 prix Tunisie',
        'min_price_tnd': 0.0,
        'median_price_tnd': 0.0,
        'max_price_tnd': 0.0,
        'confidence': 'low',
        'sources': [],
        'warnings': ['SERPAPI_API_KEY not configured...']
      }
```

---

## With API Key Configured

```
1. USER
   └─ research_serpapi_prices("Peugeot", "208", 2018, "phare")

2. CHECK CACHE
   └─ data/serpapi_price_cache.csv
      • No match found (first run)

3. GENERATE QUERY
   └─ "phare OR optique OR feu avant Peugeot 208 2018 prix Tunisie"

4. CHECK API KEY
   └─ SERPAPI_API_KEY = "abc123..." ✓

5. CALL SERPAPI
   └─ https://serpapi.com/search?api_key=abc123...&q=phare+OR+optique...
      • Response: 10 organic results

6. EXTRACT PRICES
   └─ Result 1: "Phare Peugeot 208 450 TND" → 450.0
   └─ Result 2: "Optique avant 208 prix 520 DT" → 520.0
   └─ Result 3: "Feu avant Peugeot 600 TND" → 600.0
   └─ Result 4: "Phare 20 TND" → REJECTED (below minimum)
   └─ Valid prices: [450.0, 520.0, 600.0]

7. SCORE SOURCES
   └─ Result 1: karhabtk.tn → relevance=0.7 (Tunisian)
   └─ Result 2: autopart.tn → relevance=0.6 (Tunisian)
   └─ Result 3: example.com → relevance=0.0 (non-Tunisian)

8. CALCULATE CONFIDENCE
   └─ 3 prices found
   └─ 2 Tunisian sources
   └─ Confidence: HIGH ✓

9. SAVE TO CACHE
   └─ data/serpapi_price_cache.csv
      • expires_at: 2026-07-06 (30 days)

10. RETURN RESULT
    └─ {
         'status': 'serpapi_success',
         'cache_hit': False,
         'query': 'phare OR optique OR "feu avant" Peugeot 208 2018 prix Tunisie',
         'min_price_tnd': 450.0,
         'median_price_tnd': 520.0,
         'max_price_tnd': 600.0,
         'confidence': 'high',
         'sources': [
           {'title': 'Phare Peugeot 208', 'domain': 'karhabtk.tn', ...},
           {'title': 'Optique avant 208', 'domain': 'autopart.tn', ...},
           ...
         ],
         'warnings': []
       }
```

---

## Cache Hit Scenario (Second Run)

```
1. USER
   └─ research_serpapi_prices("Peugeot", "208", 2018, "phare")

2. CHECK CACHE
   └─ data/serpapi_price_cache.csv
      • Match found: Peugeot 208 2018 phare
      • expires_at: 2026-07-06 (still valid)
      • Return cached result immediately

3. RETURN RESULT (FROM CACHE)
   └─ {
        'status': 'cache_hit',
        'cache_hit': True,
        'query': 'phare OR optique OR "feu avant" Peugeot 208 2018 prix Tunisie',
        'min_price_tnd': 450.0,
        'median_price_tnd': 520.0,
        'max_price_tnd': 600.0,
        'confidence': 'high',
        'sources': [...],
        'cached_at': '2026-06-06T14:00:00',
        'expires_at': '2026-07-06T14:00:00',
        'warnings': ['Using cached SerpAPI result']
      }

   NO API CALL MADE (quota saved)
```

---

## Component Interaction

```
┌─────────────────┐
│  Test Script    │
└────────┬────────┘
         │
         │ import
         ▼
┌─────────────────────────────────────────┐
│  serpapi_price_researcher.py            │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  research_serpapi_prices()      │   │
│  └─────────────────────────────────┘   │
│           │                             │
│           ├─ generate_optimized_query() │
│           ├─ check_serpapi_cache()      │
│           ├─ perform_serpapi_search()   │
│           ├─ extract_prices_from_text() │
│           ├─ score_source_relevance()   │
│           └─ save_to_serpapi_cache()    │
└─────────────────────────────────────────┘
         │              │
         │              │ read/write
         ▼              ▼
┌─────────────┐  ┌──────────────────┐
│  SerpAPI    │  │  Cache CSV       │
│  (external) │  │  (local file)    │
└─────────────┘  └──────────────────┘
```

---

## Comparison: Standalone vs Integrated

### Current: Standalone (✅ Implemented)

```
┌──────────────────────────────────────────────────────────────┐
│  COST ESTIMATOR                                               │
│                                                               │
│  1. Karhabtk collected prices (parts_prices_collected.csv)   │
│  2. Manual CSV fallback (parts_prices.csv)                   │
│  3. Manual estimation                                        │
│                                                               │
│  NO INTEGRATION with SerpAPI researcher                       │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  SERPAPI RESEARCHER (Standalone)                              │
│                                                               │
│  • Can be tested independently                                │
│  • Run via test script                                        │
│  • Zero risk to existing code                                 │
│  • Demonstrates capability                                    │
└──────────────────────────────────────────────────────────────┘
```

### Future: Integrated (⏸️ Not Implemented)

```
┌──────────────────────────────────────────────────────────────┐
│  COST ESTIMATOR (with SerpAPI integration)                    │
│                                                               │
│  1. Karhabtk collected prices (parts_prices_collected.csv)   │
│  2. Manual CSV fallback (parts_prices.csv)                   │
│  3. SerpAPI researcher (if enabled + confidence >= medium)    │
│  4. Manual estimation                                        │
│                                                               │
│  Integration requires:                                        │
│  • Import serpapi_price_researcher                            │
│  • Add to fallback chain                                      │
│  • Test thoroughly                                            │
│  • Add configuration flag                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Language
- **Python 3.x**

### Standard Libraries
- `os` - Environment variables, file paths
- `csv` - Cache file I/O
- `re` - Price extraction regex
- `json` - JSON encoding/decoding
- `statistics` - Median calculation
- `datetime` - Cache expiration
- `urllib.request` - HTTP requests
- `urllib.error` - Error handling
- `urllib.parse` - URL encoding

### External Services
- **SerpAPI** - Google search API
  - Endpoint: https://serpapi.com/search
  - Authentication: API key
  - Free tier: 100 searches/month

### Data Storage
- **CSV file** - Local cache
  - Path: data/serpapi_price_cache.csv
  - Format: UTF-8 encoded CSV
  - No database required

---

## Error Handling

### 1. Missing API Key
```python
if not SERPAPI_API_KEY:
    return {
        'status': 'serpapi_key_missing',
        'warnings': ['Set SERPAPI_API_KEY environment variable']
    }
```

### 2. API Request Failure
```python
except urllib.error.HTTPError as e:
    print(f"SerpAPI HTTP error: {e.code}")
    # Cache negative result for 7 days
    return {'status': 'serpapi_api_error'}
```

### 3. Connection Timeout
```python
with urllib.request.urlopen(req, timeout=10) as response:
    # 10-second timeout prevents hanging
```

### 4. Invalid JSON Response
```python
try:
    data = json.loads(response.read())
except json.JSONDecodeError:
    print("Failed to parse SerpAPI response")
    return {'status': 'serpapi_api_error'}
```

### 5. Cache I/O Error
```python
try:
    with open(CACHE_PATH, 'r') as f:
        reader = csv.DictReader(f)
except Exception as e:
    print(f"Warning: Failed to load cache: {e}")
    return []  # Continue without cache
```

---

## Security Considerations

### 1. API Key Protection
- Stored in environment variable (not in code)
- Never logged or printed (except test output shows first 8 + last 4 chars)
- Not committed to git

### 2. Request Timeout
- 10-second timeout prevents hanging
- Non-blocking error handling

### 3. Input Validation
- Part category sanity ranges
- Price value validation
- URL parsing error handling

### 4. Cache Safety
- UTF-8 encoding for international characters
- JSON escaping for sources
- CSV newline handling

---

## Performance Optimization

### 1. Cache-First Approach
- Checks cache before API call
- 30-day validity reduces API usage
- Instant response on cache hit

### 2. Single Query Strategy
- One query per vehicle/part (not 3)
- OR operators combine synonyms
- Saves API quota

### 3. Minimal API Calls
- Cache protects quota
- 7-day negative cache avoids repeated failures
- Request timeout prevents hanging

### 4. Efficient Price Extraction
- Compiled regex patterns
- Early rejection of invalid prices
- Set-based deduplication

---

**Last Updated:** 2026-06-06  
**Status:** ✅ Architecture Complete  
**Implementation:** ✅ Verified
