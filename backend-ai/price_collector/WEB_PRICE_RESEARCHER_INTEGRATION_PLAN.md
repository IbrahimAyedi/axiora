# Web Price Researcher Integration Plan

## Current Status

The `web_price_researcher` module is **COMPLETE and TESTED** but **NOT YET INTEGRATED** into the cost estimator.

## Current Cost Estimator Priority Chain

```
1. Collected CSV exact match (parts_prices_collected.csv)
2. Manual CSV exact match (parts_prices.csv)
3. Manual CSV Any/Any fallback
4. Rule-based fallback (0 TND part cost)
```

## Proposed Integration Priority Chain

```
1. Collected CSV exact match (parts_prices_collected.csv)
2. Manual CSV exact match (parts_prices.csv)
3. ⭐ WEB PRICE RESEARCHER (new) ⭐
4. Manual CSV Any/Any fallback
5. Rule-based fallback (0 TND part cost)
```

## Integration Point

**File:** `cost_estimator/estimator.py`

**Method:** `find_part_prices()`

**Location:** After manual CSV exact match fails, before Any/Any fallback

## Proposed Code Changes

### Step 1: Import web price researcher

```python
# At top of estimator.py
from price_collector.sources.web_price_researcher import research_web_prices
```

### Step 2: Modify find_part_prices() method

```python
def find_part_prices(self, make, model, year, part_category):
    """
    Find part prices with priority order:
    1. Collected CSV exact match
    2. Manual CSV exact match  
    3. Web price researcher (cache + optional API)
    4. Manual CSV Any/Any fallback
    5. Empty list (rule-based fallback will handle)
    
    Returns: (matches_list, data_origin)
    data_origin: 'collected_csv' | 'manual_csv' | 'web_research' | None
    """
    # ... existing PRIORITY 1 and 2 logic ...
    
    # PRIORITY 3: Web price researcher (NEW)
    if make_str != "Any" and model_str != "Any" and part_category_str != "unknown":
        try:
            # Convert year to int
            year_int = int(year_str) if year_str.isdigit() else 0
            
            web_result = research_web_prices(make_str, model_str, year_int, part_category_str)
            
            # Only use web research if we got confident prices
            if (web_result.get('status') in ['cache_hit', 'api_success'] and 
                web_result.get('median_price_tnd', 0) > 0):
                
                # Convert web research result to part price format
                median_price = web_result.get('median_price_tnd', 0)
                min_price = web_result.get('min_price_tnd', 0)
                max_price = web_result.get('max_price_tnd', 0)
                
                # Create synthetic part entries for bas/moyenne/haut
                web_parts = [
                    {
                        'make': make_str,
                        'model': model_str,
                        'year': year_str,
                        'part_category': part_category_str,
                        'part_name': f'{part_category_str} (web research)',
                        'part_brand': 'N/A',
                        'reference': 'N/A',
                        'price_tnd': min_price,
                        'source': 'web_research',
                        'source_url': web_result.get('sources', [{}])[0].get('url', 'N/A') if web_result.get('sources') else 'N/A',
                        'image_url': 'N/A',
                        'availability': 'N/A',
                        'quality_level': 'bas',
                        'confidence': web_result.get('confidence', 'low')
                    },
                    {
                        'make': make_str,
                        'model': model_str,
                        'year': year_str,
                        'part_category': part_category_str,
                        'part_name': f'{part_category_str} (web research)',
                        'part_brand': 'N/A',
                        'reference': 'N/A',
                        'price_tnd': median_price,
                        'source': 'web_research',
                        'source_url': web_result.get('sources', [{}])[0].get('url', 'N/A') if web_result.get('sources') else 'N/A',
                        'image_url': 'N/A',
                        'availability': 'N/A',
                        'quality_level': 'moyenne',
                        'confidence': web_result.get('confidence', 'low')
                    },
                    {
                        'make': make_str,
                        'model': model_str,
                        'year': year_str,
                        'part_category': part_category_str,
                        'part_name': f'{part_category_str} (web research)',
                        'part_brand': 'N/A',
                        'reference': 'N/A',
                        'price_tnd': max_price,
                        'source': 'web_research',
                        'source_url': web_result.get('sources', [{}])[0].get('url', 'N/A') if web_result.get('sources') else 'N/A',
                        'image_url': 'N/A',
                        'availability': 'N/A',
                        'quality_level': 'haut',
                        'confidence': web_result.get('confidence', 'low')
                    }
                ]
                
                return (web_parts, 'web_research')
        except Exception as e:
            # Silently fail and continue to Any/Any fallback
            print(f"Warning: Web price research failed: {e}")
            pass
    
    # PRIORITY 4: Manual CSV Any/Any fallback
    # ... existing Any/Any logic ...
```

### Step 3: Update estimate_repair_cost() to handle web_research data_origin

The existing code should already handle `data_origin = 'web_research'` correctly since it treats any non-collected_csv origin as manual CSV logic.

However, you may want to add special handling to show confidence level:

```python
# In estimate_repair_cost() where warnings are added
if data_origin == 'web_research':
    matching_part = part_options[0] if part_options else None
    if matching_part:
        confidence = matching_part.get('confidence', 'low')
        if confidence == 'low':
            warnings.append("Web research prices have low confidence. Manual verification recommended.")
        elif confidence == 'medium':
            warnings.append("Web research prices based on limited data.")
        # No warning for high confidence
```

## Benefits of This Integration

✅ **Covers missing vehicles:** Peugeot 208, Mercedes-Benz, and other vehicles not in collected CSV

✅ **Safe fallback:** Continues to Any/Any fallback if web research fails

✅ **Cached results:** 30-day cache reduces API calls

✅ **Non-breaking:** If API keys not configured, silently falls back to Any/Any

✅ **Confidence-aware:** Can skip low-confidence results if desired

## Configuration Required (Optional)

To enable live web search (otherwise uses cache or falls back):

```bash
# Windows CMD
set GOOGLE_CUSTOM_SEARCH_API_KEY=your_key_here
set GOOGLE_CUSTOM_SEARCH_ENGINE_ID=your_cse_id_here

# Windows PowerShell
$env:GOOGLE_CUSTOM_SEARCH_API_KEY="your_key_here"
$env:GOOGLE_CUSTOM_SEARCH_ENGINE_ID="your_cse_id_here"

# Linux/Mac
export GOOGLE_CUSTOM_SEARCH_API_KEY='your_key_here'
export GOOGLE_CUSTOM_SEARCH_ENGINE_ID='your_cse_id_here'
```

## Testing After Integration

Update `cost_estimator/test_estimator.py` to include:

```python
# Test with web research fallback
vehicle_web = {"make": "Peugeot", "model": "208", "year": 2018}
det_web = [{"class_name": "lamp_broken", "confidence": 0.86, "bbox_area_ratio": 0.024}]
res_web = estimate_repair_cost(vehicle_web, det_web)

# Should use web_research data_origin if:
# - API keys configured and prices found, OR
# - Cache hit from previous search
# Otherwise falls back to Any/Any
```

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| API rate limits | Cache reduces calls; low PFA usage |
| Slow response time | 10s timeout; cached results instant |
| Inaccurate prices | Confidence levels + manual verification warnings |
| Integration breaks estimator | Try/except blocks; silent fallback to Any/Any |

## When to Integrate

**Recommended timing:**
- After PFA prototype is stable
- When you want to improve Peugeot 208 price estimates
- Before expanding to more vehicle models

**Not recommended if:**
- PFA deadline is very close
- Current Any/Any fallback is acceptable
- You don't want to set up Google API credentials

## Manual Search Workflow (No API Keys)

Even without API keys, the web researcher provides value:

1. Estimator calls `research_web_prices()`
2. Returns `status: manual_search_required` with generated queries
3. User can manually search using generated queries:
   - "phare Peugeot 208 2018 prix Tunisie"
   - "optique Peugeot 208 2018 prix Tunisie"
   - "feu avant Peugeot 208 2018 prix Tunisie"
4. User manually updates `parts_prices.csv` with found prices

This provides a **guided manual research workflow** without requiring API integration.

## Summary

The web price researcher is **production-ready** but **optional**. It can be integrated when:
- You need better coverage for missing vehicles (like Peugeot 208)
- You're willing to set up Google Custom Search API
- You want to reduce manual price research effort

The integration is **low-risk** due to:
- Safe fallback behavior
- Cache-first approach
- Non-breaking changes to existing cost estimator flow
