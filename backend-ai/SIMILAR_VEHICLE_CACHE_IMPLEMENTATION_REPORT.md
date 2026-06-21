# Similar Vehicle Cache Fallback Implementation Report

**Date:** 2026-06-06  
**Project:** Car Damage Detection - Cost Estimator Module  
**Feature:** Intelligent Similar Vehicle Cache Fallback

---

## A. FILES INSPECTED

### Core Module Files:
- ✓ `cost_estimator/estimator.py` - Main cost estimation logic
- ✓ `cost_estimator/test_estimator.py` - Test suite
- ✓ `data/parts_prices_collected.csv` - Karhabtk scraped prices
- ✓ `data/parts_prices.csv` - Manual fallback prices
- ✓ `data/serpapi_price_cache.csv` - Web research price cache

---

## B. FILES MODIFIED

### 1. `cost_estimator/estimator.py`
**Changes:**
- Added `import re` and `from datetime import datetime`
- Created `extract_numeric_model()` function for model similarity calculation
- Created `find_similar_vehicle_cached_price()` function to search SerpAPI cache
- Updated `find_part_prices()` signature to return `(matches_list, data_origin, similar_vehicle_info)`
- Integrated similar vehicle cache as **Priority 3** (between manual exact and Any/Any fallback)
- Added warning generation for similar vehicle cache usage
- Added metadata fields: `reference_vehicle`, `similarity_score`, `confidence`

### 2. `cost_estimator/test_estimator.py`
**Changes:**
- Updated test suite title to "SIMILAR VEHICLE CACHE FALLBACK"
- Added 7 new tests specifically for similar vehicle cache fallback
- Updated test helper to display `reference_vehicle`, `similarity_score`, `confidence`
- Maintained all regression tests (collected CSV, manual CSV, Any/Any, edge cases)

### 3. `cost_estimator/demo_similar_cache.py` (NEW FILE)
**Purpose:**
- Created comprehensive demo script showcasing the feature
- 4 demo scenarios with detailed explanations
- JSON output examples
- Verification of priority order and make rejection

---

## C. SERPAPI CACHE USAGE

**Status:** ✅ **NOW INTEGRATED**

Previously, `serpapi_price_cache.csv` existed but was **never read** by cost_estimator.

**Now:**
- Cache is read by `find_similar_vehicle_cached_price()`
- Only uses **existing cached data** (no live SerpAPI calls)
- Validates expiry dates
- Filters out invalid prices (≤ 0)
- Respects same-make requirement

---

## D. CACHE ROWS DETECTED

**File:** `data/serpapi_price_cache.csv`

| Make | Model | Year | Part Category | Median Price TND | Expires At | Status |
|------|-------|------|---------------|------------------|------------|--------|
| Peugeot | 208 | 2018 | phare | 900.0 | 2026-07-06 | ✅ Valid |
| Renault | Symbol | 2017 | phare | 0.0 | 2026-06-13 | ❌ Invalid (price = 0) |
| Peugeot | 208 | 2018 | pneu | 300.0 | 2026-07-06 | ✅ Valid |

**Summary:**
- 3 total rows
- 2 valid rows (Peugeot 208 phare & pneu)
- 1 invalid row (Renault Symbol phare with 0 price)

---

## E. SIMILARITY LOGIC IMPLEMENTED

### Model Similarity Calculation:

```python
def extract_numeric_model(model_str):
    """
    Extract numeric portion from model string.
    Examples:
        '208' -> 208
        '206' -> 206
        'Civic' -> None
    """
    match = re.search(r'\d+', str(model_str))
    return int(match.group()) if match else None
```

### Similarity Score Formula:

```python
if both models have numeric values:
    distance = abs(target_numeric - cache_numeric)
    similarity_score = 1.0 / (1.0 + distance)
else:
    similarity_score = 0.3  # Low similarity for non-numeric
```

### Similarity Examples:

| Target | Cached | Distance | Similarity Score |
|--------|--------|----------|------------------|
| 206 | 208 | 2 | 0.333 |
| 207 | 208 | 1 | 0.500 |
| 3008 | 208 | 2800 | 0.000 |
| Civic | 208 | N/A | 0.300 |

**Best Match Selection:** Highest similarity_score wins

---

## F. PRIORITY ORDER IMPLEMENTED

### ✅ NEW PRIORITY ORDER:

1. **Collected CSV exact match** → `data_source: "collected_csv"`
2. **Manual CSV exact match** → `data_source: "manual_csv"`
3. **🆕 Similar vehicle cache fallback** → `data_source: "similar_vehicle_cache"`
4. **Manual CSV Any/Any fallback** → `data_source: "manual_csv"`
5. **Rule-based fallback** → `data_source: "rule_based_fallback"`

### Insertion Point:
Similar vehicle cache was inserted **between Priority 2 and Priority 4** to:
- ✓ Allow exact matches to take precedence
- ✓ Provide better estimates than generic Any/Any
- ✓ Maintain graceful degradation

---

## G. TESTS EXECUTED

### Test Suite: `cost_estimator/test_estimator.py`

**Total Tests:** 15 tests  
**Result:** ✅ **ALL TESTS PASS**

### New Similar Cache Tests (7 tests):

1. ✅ **Peugeot 206 + lamp_broken** → Uses similar_vehicle_cache (from Peugeot 208)
2. ✅ **Peugeot 208 + lamp_broken** → Uses manual_csv (exact match overrides)
3. ✅ **Renault Symbol + lamp_broken** → Uses collected_csv (exact match overrides)
4. ✅ **Unknown vehicle + lamp_broken** → Uses rule_based_fallback (no cache for unknown)
5. ✅ **Peugeot 3008 + lamp_broken** → Uses similar_vehicle_cache (from Peugeot 208)
6. ✅ **Renault Megane + lamp_broken** → Rejects Peugeot cache (different make)
7. ✅ **Peugeot 207 + lamp_broken** → Uses similar_vehicle_cache (high similarity)

### Regression Tests (8 tests):
- ✅ Collected CSV tests (Peugeot 205, Renault Logan)
- ✅ Manual CSV tests (Mercedes-Benz 204)
- ✅ Any/Any tests (Unknown vehicle + tire_flat)
- ✅ Edge cases (normalization, missing data, empty lists)

---

## H. TEST RESULTS

```
================================================================================
TEST SUITE COMPLETE
================================================================================
Exit Code: 0

All 15 tests PASSED ✓
```

**Key Verifications:**
- ✅ Similar cache used when no exact match exists
- ✅ Exact matches correctly override similar cache
- ✅ Different makes correctly rejected
- ✅ Unknown vehicles do NOT use similar cache
- ✅ Similarity scores calculated correctly
- ✅ All regression tests still pass

---

## I. EXAMPLE SIMILAR_VEHICLE_CACHE OUTPUT

### Scenario: Peugeot 206 + lamp_broken

```json
{
  "currency": "TND",
  "vehicle": {
    "make": "Peugeot",
    "model": "206",
    "year": "2010"
  },
  "region": "Tunis",
  "estimations": [
    {
      "original_class_name": "lamp_broken",
      "normalized_class_name": "lamp_broken",
      "confidence": 0.86,
      "severity": "bas",
      "repair_strategy": "part_replacement",
      "part_category": "phare",
      "data_source": "similar_vehicle_cache",
      "options": {
        "bas": {
          "label": "Économique",
          "part_name": "Similar vehicle price (économique)",
          "part_price": 765.0,
          "labor": 60,
          "paint": 0,
          "total": 825.0,
          "source": "serpapi_cache",
          "availability": "approximate",
          "reference_vehicle": "Peugeot 208",
          "similarity_score": 0.333,
          "confidence": "low"
        },
        "moyenne": {
          "label": "Standard",
          "part_price": 900.0,
          "labor": 90,
          "total": 990.0,
          "reference_vehicle": "Peugeot 208",
          "similarity_score": 0.333,
          "confidence": "low"
        },
        "haut": {
          "label": "Premium",
          "part_price": 1125.0,
          "labor": 120,
          "total": 1245.0,
          "reference_vehicle": "Peugeot 208",
          "similarity_score": 0.333,
          "confidence": "low"
        }
      },
      "recommended": { /* bas option */ },
      "recommended_level": "bas",
      "warnings": [
        "Exact price not found. Used cached price from similar vehicle (Peugeot 208) as approximate fallback (similarity: 0.33)."
      ]
    }
  ],
  "warning": "Estimation indicative à confirmer par un garage."
}
```

### Price Range Generation:
- **Bas (Économique):** reference × 0.85 = 765 TND
- **Moyenne (Standard):** reference = 900 TND
- **Haut (Premium):** reference × 1.25 = 1125 TND

---

## J. WARNINGS ADDED

### Warning Message Format:
```
"Exact price not found. Used cached price from similar vehicle ({make} {model}) as approximate fallback (similarity: {score:.2f})."
```

### Examples:
- Peugeot 206 → "Used cached price from similar vehicle (Peugeot 208) as approximate fallback (similarity: 0.33)."
- Peugeot 207 → "Used cached price from similar vehicle (Peugeot 208) as approximate fallback (similarity: 0.50)."

### Warning Placement:
- ✅ Added to `estimation['warnings']` array
- ✅ Displayed in API responses
- ✅ Clear indication this is NOT an exact price

---

## K. CONFIRMATION: EXACT MATCHES STILL OVERRIDE

### Test Cases Confirming Override Behavior:

**Test 2: Peugeot 208 + lamp_broken**
```
Expected: manual_csv
Result: manual_csv ✅
Verification: Exact match correctly overrides similar cache
```

**Test 3: Renault Symbol + lamp_broken**
```
Expected: collected_csv
Result: collected_csv ✅
Verification: Exact collected match overrides similar cache
```

**Test 10: Mercedes-Benz 204 + lamp_broken**
```
Expected: manual_csv
Result: manual_csv ✅
Verification: Manual exact match still works
```

### Override Logic:
```python
# Priority 1: Collected exact → return immediately
if collected_matches:
    return (unique_collected, 'collected_csv', None)

# Priority 2: Manual exact → return immediately
if len(exact_matches) >= 3:
    return (exact_matches, 'manual_csv', None)

# Priority 3: Similar cache → only reached if no exact match
similar_cache = find_similar_vehicle_cached_price(...)
if similar_cache:
    return (synthetic_parts, 'similar_vehicle_cache', similar_cache)
```

**Result:** ✅ Exact matches ALWAYS override similar fallback

---

## L. CONFIRMATION: DIFFERENT MAKE IS REJECTED

### Test Case: Renault Megane + lamp_broken

**Scenario:**
- Target: Renault Megane
- Cache contains: Peugeot 208 (different make)
- Cache contains: Renault Symbol (same make but price = 0, invalid)

**Expected:** Do NOT use Peugeot cache (different make)

**Result:**
```
Data Source: rule_based_fallback ✅
Verification: Correctly rejected Peugeot cache (different make)
```

### Rejection Logic:
```python
# MUST match make and part_category
if cache_make != target_make:
    continue  # Reject different make
```

**Examples:**
- ❌ Renault → Peugeot (REJECTED)
- ❌ Peugeot → Renault (REJECTED)
- ✅ Peugeot 206 → Peugeot 208 (ACCEPTED - same make)

---

## M. REMAINING LIMITATIONS

### 1. Cache Coverage
- **Current:** Only 2 valid cache entries (Peugeot 208 phare/pneu)
- **Impact:** Limited vehicles benefit from similar fallback
- **Mitigation:** As cache grows, more fallbacks become available

### 2. Non-Numeric Models
- **Examples:** Renault "Megane", Honda "Civic", Toyota "Corolla"
- **Behavior:** Uses low similarity score (0.3)
- **Impact:** May match but with lower confidence

### 3. Cross-Make Similarity
- **Current:** Only same-make similarity allowed
- **Rationale:** Different makes have vastly different part prices
- **Example:** Mercedes parts ≠ Peugeot parts

### 4. Year Ignored
- **Current:** Year is stored but not used in similarity calculation
- **Rationale:** Model generation more important than year
- **Future:** Could add year proximity as tiebreaker

### 5. Expiry Handling
- **Current:** Expired entries ignored silently
- **Impact:** Cache becomes stale over time
- **Mitigation:** SerpAPI researcher can refresh cache

### 6. No Live SerpAPI Calls
- **Current:** Only uses existing cache
- **Benefit:** No API costs, no rate limits
- **Limitation:** Cannot discover new prices on-demand

---

## N. CHECKLIST

### ✅ DONE

- [x] Phase 1: Full inspection of all relevant files
- [x] Phase 2: Implement `find_similar_vehicle_cached_price()`
- [x] Phase 3: Implement model similarity logic
- [x] Phase 4: Implement price range generation (0.85x, 1.0x, 1.25x)
- [x] Phase 5: Insert similar cache at correct priority level
- [x] Phase 6: Update test suite with 7 new tests
- [x] Phase 7: Run tests - all 15 tests pass
- [x] Phase 8: Create comprehensive report
- [x] Add warnings for approximate fallback
- [x] Add metadata fields (reference_vehicle, similarity_score, confidence)
- [x] Verify exact matches override similar fallback
- [x] Verify different makes are rejected
- [x] Create demo script with 4 scenarios
- [x] Test edge cases (unknown vehicle, expired cache, invalid prices)
- [x] Maintain JSON output stability
- [x] No modifications to YOLO, API, Flutter, or scraping code
- [x] No live API calls
- [x] No CSV overwrites

### ⚠️ PARTIAL

None - all features fully implemented

### 📋 TODO (Future Enhancements)

- [ ] Add year proximity as tiebreaker when similarity scores are equal
- [ ] Expand cache coverage with more vehicles and part categories
- [ ] Add cache refresh mechanism (manual trigger, not automatic)
- [ ] Consider cross-part-category similarity (e.g., phare → feu)
- [ ] Add cache statistics to API /health endpoint
- [ ] Log cache hit/miss metrics for monitoring

---

## SUMMARY

✅ **Feature successfully implemented and tested**

**What was added:**
- Intelligent similar vehicle cache fallback using existing SerpAPI cache
- Numeric model similarity calculation
- Price range generation based on cached reference prices
- Clear warnings for approximate fallbacks
- Comprehensive test coverage

**What was preserved:**
- All existing priority levels (collected, manual, Any/Any, rule-based)
- Exact matches always override similar fallback
- Different makes strictly rejected
- JSON output structure stable
- No modifications to YOLO, API, or scraping logic

**Impact:**
- Peugeot 206, 207, 3008, etc. now get approximate prices from Peugeot 208 cache
- Better than 0 TND rule-based fallback
- Clear transparency with warnings and low confidence indicators
- Graceful degradation maintained

**Ready for:**
- ✅ Integration testing
- ✅ User acceptance testing
- ✅ Production deployment

---

**Report Generated:** 2026-06-06  
**Implementation Status:** ✅ COMPLETE
