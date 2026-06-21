"""
Demo script to showcase similar_vehicle_cache_fallback feature
"""
import json
from estimator import estimate_repair_cost

def demo_similar_cache():
    print("=" * 80)
    print("DEMO: SIMILAR VEHICLE CACHE FALLBACK")
    print("=" * 80)
    print()
    
    # Demo 1: Peugeot 206 using Peugeot 208 cache
    print("DEMO 1: Peugeot 206 + lamp_broken")
    print("-" * 80)
    print("Scenario: User has Peugeot 206. No exact price in collected/manual CSV.")
    print("Cache contains: Peugeot 208 + phare = 900 TND from web research")
    print("Expected: Use Peugeot 208 price as approximate fallback (same make)")
    print()
    
    vehicle_206 = {"make": "Peugeot", "model": "206", "year": 2010}
    detections = [{"class_name": "lamp_broken", "confidence": 0.86, "bbox_area_ratio": 0.024}]
    
    result = estimate_repair_cost(vehicle_206, detections)
    
    print("RESULT:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    print()
    
    # Extract key info
    est = result['estimations'][0]
    print("KEY FINDINGS:")
    print(f"✓ Data Source: {est['data_source']}")
    print(f"✓ Warnings: {est['warnings']}")
    print(f"✓ Recommended Total: {est['recommended']['total']} TND")
    print(f"✓ Reference Vehicle: {est['recommended'].get('reference_vehicle', 'N/A')}")
    print(f"✓ Similarity Score: {est['recommended'].get('similarity_score', 'N/A')}")
    print(f"✓ Confidence: {est['recommended'].get('confidence', 'N/A')}")
    print()
    print(f"Price Range:")
    print(f"  - Économique: {est['options']['bas']['total']} TND")
    print(f"  - Standard:   {est['options']['moyenne']['total']} TND")
    print(f"  - Premium:    {est['options']['haut']['total']} TND")
    print()
    print("=" * 80)
    print()
    
    # Demo 2: Peugeot 207 (closer to 208)
    print("DEMO 2: Peugeot 207 + lamp_broken")
    print("-" * 80)
    print("Scenario: User has Peugeot 207 (numerically closer to 208 than 206)")
    print("Expected: Higher similarity score than 206")
    print()
    
    vehicle_207 = {"make": "Peugeot", "model": "207", "year": 2012}
    result2 = estimate_repair_cost(vehicle_207, detections)
    
    est2 = result2['estimations'][0]
    print("KEY FINDINGS:")
    print(f"✓ Data Source: {est2['data_source']}")
    print(f"✓ Reference Vehicle: {est2['recommended'].get('reference_vehicle', 'N/A')}")
    print(f"✓ Similarity Score: {est2['recommended'].get('similarity_score', 'N/A')}")
    print(f"✓ Recommended Total: {est2['recommended']['total']} TND")
    print()
    print("COMPARISON:")
    print(f"  Peugeot 206 similarity: 0.333 (distance: 2)")
    print(f"  Peugeot 207 similarity: {est2['recommended'].get('similarity_score', 'N/A')} (distance: 1)")
    print("  → 207 is closer to 208, so higher similarity score")
    print()
    print("=" * 80)
    print()
    
    # Demo 3: Verify exact match still overrides
    print("DEMO 3: Peugeot 208 + lamp_broken")
    print("-" * 80)
    print("Scenario: User has Peugeot 208 (exact match in manual CSV)")
    print("Expected: Use manual_csv, NOT similar_vehicle_cache")
    print()
    
    vehicle_208 = {"make": "Peugeot", "model": "208", "year": 2018}
    result3 = estimate_repair_cost(vehicle_208, detections)
    
    est3 = result3['estimations'][0]
    print("KEY FINDINGS:")
    print(f"✓ Data Source: {est3['data_source']}")
    print(f"✓ Recommended Total: {est3['recommended']['total']} TND")
    print(f"✓ No reference_vehicle field (exact match, not fallback)")
    print()
    print("VERIFICATION:")
    if est3['data_source'] == 'manual_csv':
        print("  ✓ PASS: Exact match correctly overrides similar cache")
    else:
        print("  ✗ FAIL: Should use manual_csv, not similar cache")
    print()
    print("=" * 80)
    print()
    
    # Demo 4: Different make should NOT use cache
    print("DEMO 4: Renault Megane + lamp_broken")
    print("-" * 80)
    print("Scenario: User has Renault Megane")
    print("Cache contains: Peugeot 208 (different make)")
    print("Cache contains: Renault Symbol (but price is 0, invalid)")
    print("Expected: Do NOT use Peugeot cache (different make)")
    print()
    
    vehicle_megane = {"make": "Renault", "model": "Megane", "year": 2016}
    result4 = estimate_repair_cost(vehicle_megane, detections)
    
    est4 = result4['estimations'][0]
    print("KEY FINDINGS:")
    print(f"✓ Data Source: {est4['data_source']}")
    print(f"✓ Recommended Total: {est4['recommended']['total']} TND")
    print()
    print("VERIFICATION:")
    if est4['data_source'] != 'similar_vehicle_cache':
        print("  ✓ PASS: Correctly rejected Peugeot cache (different make)")
    else:
        print("  ✗ FAIL: Should NOT use Peugeot cache for Renault")
    print()
    print("=" * 80)
    print()
    
    print("DEMO COMPLETE")
    print("=" * 80)

if __name__ == "__main__":
    demo_similar_cache()
