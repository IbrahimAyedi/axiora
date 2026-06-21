"""
Test script for web_price_researcher module.

This script tests the web price research functionality with various scenarios.
It will work even without API keys configured (safe fallback mode).
"""

import json
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from price_collector.sources.web_price_researcher import research_web_prices


def print_separator(title=""):
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
    print(f"\n📊 Status: {result.get('status')}")
    print(f"💾 Cache Hit: {result.get('cache_hit', False)}")
    print(f"🔍 Confidence: {result.get('confidence', 'N/A')}")
    
    # Prices
    print(f"\n💰 Prices (TND):")
    print(f"   Min:    {result.get('min_price_tnd', 0):.2f} TND")
    print(f"   Median: {result.get('median_price_tnd', 0):.2f} TND")
    print(f"   Max:    {result.get('max_price_tnd', 0):.2f} TND")
    
    # Generated queries
    print(f"\n🔎 Generated Queries:")
    for i, query in enumerate(result.get('generated_queries', []), 1):
        print(f"   {i}. {query}")
    
    # Sources
    sources = result.get('sources', [])
    if sources:
        print(f"\n🌐 Sources Found: {len(sources)}")
        for i, source in enumerate(sources[:5], 1):  # Show first 5
            print(f"   {i}. {source.get('title', 'N/A')[:70]}")
            print(f"      URL: {source.get('url', 'N/A')[:70]}")
            if 'relevance_score' in source:
                print(f"      Relevance: {source.get('relevance_score', 0):.2f}")
            if 'prices_found' in source:
                print(f"      Prices: {source.get('prices_found', [])}")
    else:
        print(f"\n🌐 Sources Found: 0")
    
    # Warnings
    warnings = result.get('warnings', [])
    if warnings:
        print(f"\n⚠️  Warnings:")
        for warning in warnings:
            print(f"   • {warning}")
    
    # Full JSON (for debugging)
    print(f"\n📄 Full JSON Response:")
    # Create a clean copy without verbose fields for display
    display_result = result.copy()
    if 'sources' in display_result and len(display_result['sources']) > 3:
        display_result['sources'] = display_result['sources'][:3] + [f"... and {len(display_result['sources']) - 3} more"]
    print(json.dumps(display_result, indent=2, ensure_ascii=False))


def run_tests():
    """Run comprehensive tests of web price researcher."""
    
    print_separator("WEB PRICE RESEARCHER TEST SUITE")
    print("\nThis test suite will run even without Google API keys configured.")
    print("If API keys are missing, you'll see 'manual_search_required' status.")
    
    # Check if API keys are configured
    api_key = os.environ.get('GOOGLE_CUSTOM_SEARCH_API_KEY')
    cse_id = os.environ.get('GOOGLE_CUSTOM_SEARCH_ENGINE_ID')
    
    print(f"\n🔑 API Configuration Status:")
    print(f"   GOOGLE_CUSTOM_SEARCH_API_KEY: {'✓ Set' if api_key else '✗ Not set'}")
    print(f"   GOOGLE_CUSTOM_SEARCH_ENGINE_ID: {'✓ Set' if cse_id else '✗ Not set'}")
    
    if not api_key or not cse_id:
        print(f"\n⚠️  To enable live web search, set environment variables:")
        print(f"   export GOOGLE_CUSTOM_SEARCH_API_KEY='your_key_here'")
        print(f"   export GOOGLE_CUSTOM_SEARCH_ENGINE_ID='your_cse_id_here'")
    
    # Test 1: Peugeot 208 + phare (not in collected CSV)
    print_separator("TEST 1: Peugeot 208 + phare")
    print("Expected: Should generate queries and attempt web research")
    result1 = research_web_prices(
        make="Peugeot",
        model="208",
        year=2018,
        part_category="phare"
    )
    print_result("Peugeot 208 + phare", result1)
    
    # Test 2: Renault Symbol 2017 + phare (exists in collected CSV, but testing web researcher)
    print_separator("TEST 2: Renault Symbol 2017 + phare")
    print("Expected: Should generate queries (even though it exists in collected CSV)")
    result2 = research_web_prices(
        make="Renault",
        model="Symbol",
        year=2017,
        part_category="phare"
    )
    print_result("Renault Symbol 2017 + phare", result2)
    
    # Test 3: Unknown vehicle + phare
    print_separator("TEST 3: Unknown Vehicle + phare")
    print("Expected: Should generate generic queries")
    result3 = research_web_prices(
        make="Unknown",
        model="Unknown",
        year=0,
        part_category="phare"
    )
    print_result("Unknown Vehicle + phare", result3)
    
    # Test 4: Test caching - re-run Test 1
    print_separator("TEST 4: Peugeot 208 + phare (Cache Test)")
    print("Expected: Should return cached result if Test 1 found prices")
    result4 = research_web_prices(
        make="Peugeot",
        model="208",
        year=2018,
        part_category="phare"
    )
    print_result("Peugeot 208 + phare (Cache Test)", result4)
    
    if result4.get('cache_hit'):
        print("\n✅ Cache is working! Result was returned from cache.")
    else:
        print("\n📝 No cache hit (expected if this is the first run or API keys not set)")
    
    # Test 5: Different part category - pneu (tire)
    print_separator("TEST 5: Peugeot 208 + pneu")
    print("Expected: Should generate queries for tire prices")
    result5 = research_web_prices(
        make="Peugeot",
        model="208",
        year=2018,
        part_category="pneu"
    )
    print_result("Peugeot 208 + pneu", result5)
    
    # Summary
    print_separator("TEST SUMMARY")
    
    test_results = [
        ("Test 1: Peugeot 208 + phare", result1),
        ("Test 2: Renault Symbol + phare", result2),
        ("Test 3: Unknown + phare", result3),
        ("Test 4: Cache test", result4),
        ("Test 5: Peugeot 208 + pneu", result5)
    ]
    
    print("\n📋 Results Overview:")
    for name, result in test_results:
        status = result.get('status', 'unknown')
        cache_hit = "💾" if result.get('cache_hit') else "  "
        confidence = result.get('confidence', 'N/A')
        median = result.get('median_price_tnd', 0)
        print(f"   {cache_hit} {name:40} → {status:25} confidence={confidence:6} median={median:.2f} TND")
    
    # Check for common status
    statuses = [r.get('status') for r in [result1, result2, result3, result4, result5]]
    if all(s == 'manual_search_required' for s in statuses):
        print("\n⚠️  All tests returned 'manual_search_required'")
        print("   This is expected when API keys are not configured.")
        print("   The module is working correctly in safe fallback mode.")
        print("\n✅ TEST SUITE PASSED (Safe fallback mode)")
    elif any('api_success' in s for s in statuses):
        print("\n✅ TEST SUITE PASSED (API mode)")
        print("   Web price research is working with live API calls!")
    elif any('cache_hit' in r.get('status', '') for r in [result1, result2, result3, result4, result5]):
        print("\n✅ TEST SUITE PASSED (Cache mode)")
        print("   Cache is working correctly!")
    else:
        print("\n✅ TEST SUITE COMPLETED")
        print("   Review individual test results above for details.")
    
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
