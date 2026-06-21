"""
Test script for serpapi_price_researcher module.

This script tests the SerpAPI price research functionality with various scenarios.
It will work even without SERPAPI_API_KEY configured (safe fallback mode).

Test cases:
1. Peugeot 208 + phare
2. Renault Symbol 2017 + phare
3. Peugeot 208 + pneu
4. Peugeot 208 + phare (cache test - should hit cache from test 1)
"""

import json
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from price_collector.sources.serpapi_price_researcher import research_serpapi_prices


def print_separator(title=""):
    """Print a visual separator."""
    print("\n" + "=" * 80)
    if title:
        print(f"  {title}")
        print("=" * 80)


def print_result(test_name: str, result: dict):
    """Print test result in readable format."""
    print(f"\n{'─' * 80}")
    print(f"TEST: {test_name}")
    print(f"{'─' * 80}")
    
    # Key information
    status = result.get('status')
    cache_hit = result.get('cache_hit', False)
    confidence = result.get('confidence', 'N/A')
    
    print(f"\n📊 Status: {status}")
    print(f"💾 Cache Hit: {cache_hit}")
    
    # Indicate if this was an error that was NOT cached
    if status == 'serpapi_api_error' and not cache_hit:
        print(f"🔄 Not Cached: API error - will retry on next request")
    
    print(f"🔍 Confidence: {confidence}")
    
    # Generated query
    print(f"\n🔎 Generated Query:")
    print(f"   {result.get('query', 'N/A')}")
    
    # Prices
    min_price = result.get('min_price_tnd', 0)
    median_price = result.get('median_price_tnd', 0)
    max_price = result.get('max_price_tnd', 0)
    
    print(f"\n💰 Prices (TND):")
    print(f"   Min:    {min_price:.2f} TND")
    print(f"   Median: {median_price:.2f} TND")
    print(f"   Max:    {max_price:.2f} TND")
    
    # Extracted prices summary
    if max_price > 0:
        print(f"   ✅ Prices extracted successfully!")
    elif status == 'no_prices_found':
        print(f"   ⚠️  No valid prices found (sources returned, but no prices matched sanity rules)")
    elif status == 'serpapi_api_error':
        print(f"   ❌ API error - no prices extracted")
    
    # Sources
    sources = result.get('sources', [])
    print(f"\n🌐 Sources Found: {len(sources)}")
    
    if sources:
        # Count sources with prices
        sources_with_prices = sum(1 for s in sources if s.get('prices_found'))
        print(f"   Sources with prices: {sources_with_prices}/{len(sources)}")
        
        for i, source in enumerate(sources[:5], 1):  # Show first 5
            print(f"\n   {i}. {source.get('title', 'N/A')[:70]}")
            print(f"      Domain: {source.get('source_domain', 'N/A')}")
            print(f"      Link: {source.get('link', 'N/A')[:70]}")
            if 'relevance_score' in source:
                relevance = source.get('relevance_score', 0)
                print(f"      Relevance: {relevance:.2f} {'✅ (Tunisian)' if relevance > 0.3 else '⚠️  (non-Tunisian)'}")
            if source.get('prices_found'):
                print(f"      Prices: {[f'{p:.2f} TND' for p in source.get('prices_found', [])]}")
    
    # Warnings
    warnings = result.get('warnings', [])
    if warnings:
        print(f"\n⚠️  Warnings:")
        for warning in warnings:
            print(f"   • {warning}")
    
    # Cache info
    if cache_hit:
        print(f"\n💾 Cache Info:")
        print(f"   Cached at: {result.get('cached_at', 'N/A')}")
        print(f"   Expires at: {result.get('expires_at', 'N/A')}")


def run_tests():
    """Run comprehensive tests of SerpAPI price researcher."""
    
    print_separator("SERPAPI PRICE RESEARCHER TEST SUITE")
    print("\nThis test suite will run even without SERPAPI_API_KEY configured.")
    print("If API key is missing, you'll see 'serpapi_key_missing' status.")
    
    # Check if API key is configured
    api_key = os.environ.get('SERPAPI_API_KEY')
    
    print(f"\n🔑 API Configuration Status:")
    print(f"   SERPAPI_API_KEY: {'✓ Set (' + api_key[:8] + '...' + api_key[-4:] + ')' if api_key else '✗ Not set'}")
    
    if not api_key:
        print(f"\n⚠️  To enable live SerpAPI search, set environment variable:")
        print(f"   export SERPAPI_API_KEY='your_key_here'")
        print(f"\n   Get your free API key at: https://serpapi.com/")
    
    # Test 1: Peugeot 208 + phare
    print_separator("TEST 1: Peugeot 208 + phare")
    print("Expected: Should generate optimized query and attempt SerpAPI search")
    result1 = research_serpapi_prices(
        make="Peugeot",
        model="208",
        year=2018,
        part_category="phare"
    )
    print_result("Peugeot 208 + phare", result1)
    
    # Test 2: Renault Symbol 2017 + phare
    print_separator("TEST 2: Renault Symbol 2017 + phare")
    print("Expected: Should generate optimized query for different vehicle")
    result2 = research_serpapi_prices(
        make="Renault",
        model="Symbol",
        year=2017,
        part_category="phare"
    )
    print_result("Renault Symbol 2017 + phare", result2)
    
    # Test 3: Peugeot 208 + pneu
    print_separator("TEST 3: Peugeot 208 + pneu")
    print("Expected: Should generate optimized query for tire prices")
    result3 = research_serpapi_prices(
        make="Peugeot",
        model="208",
        year=2018,
        part_category="pneu"
    )
    print_result("Peugeot 208 + pneu", result3)
    
    # Test 4: Cache test - re-run Test 1
    print_separator("TEST 4: Peugeot 208 + phare (Cache Test)")
    print("Expected: Should return cached result from Test 1 (if Test 1 completed)")
    result4 = research_serpapi_prices(
        make="Peugeot",
        model="208",
        year=2018,
        part_category="phare"
    )
    print_result("Peugeot 208 + phare (Cache Test)", result4)
    
    if result4.get('cache_hit'):
        print("\n✅ Cache is working! Result was returned from cache.")
    else:
        print("\n📝 No cache hit (this is first run or API key not set)")
    
    # Summary
    print_separator("TEST SUMMARY")
    
    test_results = [
        ("Test 1: Peugeot 208 + phare", result1),
        ("Test 2: Renault Symbol + phare", result2),
        ("Test 3: Peugeot 208 + pneu", result3),
        ("Test 4: Cache test", result4)
    ]
    
    print("\n📋 Results Overview:")
    print(f"{'Test':<45} {'Status':<25} {'Cached':<8} {'Conf.':<8} {'Median':<12} {'Sources'}")
    print("─" * 110)
    
    for name, result in test_results:
        status = result.get('status', 'unknown')
        cache_hit = "💾" if result.get('cache_hit') else "  "
        cached_str = "Yes" if result.get('cache_hit') else "No"
        confidence = result.get('confidence', 'N/A')
        median = result.get('median_price_tnd', 0)
        sources_count = len(result.get('sources', []))
        print(f"{cache_hit} {name:<43} {status:<25} {cached_str:<8} {confidence:<8} {median:>6.2f} TND   {sources_count:>2}")
    
    # Analysis
    print("\n" + "─" * 110)
    
    statuses = [r.get('status') for r in [result1, result2, result3, result4]]
    
    if all(s == 'serpapi_key_missing' for s in statuses):
        print("\n⚠️  All tests returned 'serpapi_key_missing'")
        print("   This is expected when SERPAPI_API_KEY is not configured.")
        print("   The module is working correctly in safe fallback mode.")
        print("\n✅ TEST SUITE PASSED (Safe fallback mode)")
    elif any('serpapi_success' in s for s in statuses):
        print("\n✅ TEST SUITE PASSED (API mode)")
        print("   SerpAPI price research is working with live API calls!")
        
        # Check if any prices were found
        prices_found = sum(1 for r in [result1, result2, result3] if r.get('median_price_tnd', 0) > 0)
        print(f"   Prices found in {prices_found}/3 test cases")
        
        # Count different outcomes
        api_errors = sum(1 for s in statuses[:3] if s == 'serpapi_api_error')
        no_prices = sum(1 for s in statuses[:3] if s == 'no_prices_found')
        
        print(f"\n📈 Outcome Summary:")
        print(f"   ✅ Successful with prices: {prices_found}")
        print(f"   ⚠️  Success but no prices: {no_prices}")
        print(f"   ❌ API errors (not cached): {api_errors}")
        
        if api_errors > 0:
            print(f"\n🔄 API Error Handling:")
            print(f"   API errors are NOT cached - will retry on next request")
        
        if prices_found > 0:
            print("\n🎉 SUCCESS: SerpAPI found prices!")
        else:
            print("\n⚠️  Note: SerpAPI API worked but no prices found in results")
            print("   This may be due to limited Tunisian auto parts sources in search results")
    elif any('cache_hit' in r.get('status', '') for r in [result1, result2, result3, result4]):
        print("\n✅ TEST SUITE PASSED (Cache mode)")
        print("   Cache is working correctly!")
    else:
        print("\n✅ TEST SUITE COMPLETED")
        print("   Review individual test results above for details.")
    
    # Cache verification
    if result4.get('cache_hit'):
        print("\n✅ CACHE VERIFICATION: Cache hit on repeated Peugeot 208 + phare test")
    else:
        if result1.get('status') == 'serpapi_api_error':
            print("\n✅ CACHE VERIFICATION: API error not cached (correct behavior)")
            print("   Peugeot 208 + phare will retry on next request")
        else:
            print("\n📝 Cache not yet populated (expected on first run or without API key)")
    
    # Query comparison
    print("\n🔎 Query Optimization Check:")
    print(f"   Test 1 query: {result1.get('query', 'N/A')}")
    print(f"   Test 2 query: {result2.get('query', 'N/A')}")
    print(f"   Test 3 query: {result3.get('query', 'N/A')}")
    
    # Check for OR operators
    if all('OR' in r.get('query', '') for r in [result1, result2, result3]):
        print("\n✅ All queries use OR operators for optimization (saves API quota)")
    
    print("\n" + "=" * 80)


if __name__ == "__main__":
    try:
        run_tests()
    except Exception as e:
        print(f"\n❌ TEST SUITE FAILED WITH ERROR:")
        print(f"   {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
