import json
from estimator import estimate_repair_cost

def run_tests():
    print("=" * 80)
    print("COST ESTIMATOR TEST SUITE - SIMILAR VEHICLE CACHE FALLBACK")
    print("=" * 80)
    print()

    # Helper function to print test details
    def print_test(name, result, expected_source=None):
        print(f"--- {name} ---")
        
        # Extract key information for quick review
        vehicle = result.get('vehicle', {})
        print(f"Vehicle: {vehicle.get('make')} {vehicle.get('model')} {vehicle.get('year')}")
        
        for i, est in enumerate(result.get('estimations', [])):
            print(f"\nEstimation {i+1}:")
            print(f"  Class: {est.get('original_class_name')} → {est.get('normalized_class_name')}")
            print(f"  Severity: {est.get('severity')}")
            print(f"  Data Source: {est.get('data_source')}")
            print(f"  Recommended Level: {est.get('recommended_level')}")
            
            rec = est.get('recommended', {})
            print(f"  Recommended Total: {rec.get('total')} TND")
            print(f"    - Part: {rec.get('part_price')} TND ({rec.get('part_name')})")
            print(f"    - Labor: {rec.get('labor')} TND")
            print(f"    - Paint: {rec.get('paint')} TND")
            print(f"    - Source: {rec.get('source')}")
            
            # Similar vehicle cache specific fields
            if 'reference_vehicle' in rec:
                print(f"    - Reference Vehicle: {rec.get('reference_vehicle')}")
                print(f"    - Similarity Score: {rec.get('similarity_score', 0):.3f}")
                print(f"    - Confidence: {rec.get('confidence')}")
            
            if est.get('warnings'):
                print(f"  Warnings:")
                for w in est.get('warnings'):
                    print(f"    * {w}")
            
            # Verify expected source if provided
            if expected_source:
                actual_source = est.get('data_source')
                status = "✓ PASS" if actual_source == expected_source else f"✗ FAIL (expected {expected_source}, got {actual_source})"
                print(f"  Source Check: {status}")
            
            # Show all quality options for similar_vehicle_cache
            if est.get('data_source') == 'similar_vehicle_cache':
                print(f"\n  All Options:")
                for level in ['bas', 'moyenne', 'haut']:
                    opt = est.get('options', {}).get(level, {})
                    print(f"    {level.upper()}: {opt.get('part_price')} TND (total: {opt.get('total')} TND)")
        
        print("\n")

    print("=" * 80)
    print("NEW TESTS: SIMILAR VEHICLE CACHE FALLBACK")
    print("=" * 80)
    
    # Test 1: Peugeot 206 + lamp_broken (should use similar_vehicle_cache from Peugeot 208)
    print("\n### Test 1: Peugeot 206 + lamp_broken ###")
    print("Expected: similar_vehicle_cache (from Peugeot 208 cache)")
    print("Expected warning about approximate fallback")
    print("Expected reference_vehicle: Peugeot 208")
    vehicle_206 = {"make": "Peugeot", "model": "206", "year": 2010}
    det_lamp = [{"class_name": "lamp_broken", "confidence": 0.86, "bbox_area_ratio": 0.024}]
    res1 = estimate_repair_cost(vehicle_206, det_lamp)
    print_test("Peugeot 206 + lamp_broken", res1, expected_source="similar_vehicle_cache")

    # Test 2: Peugeot 208 + lamp_broken (should use manual_csv, NOT similar cache)
    print("\n### Test 2: Peugeot 208 + lamp_broken ###")
    print("Expected: manual_csv (exact match should override similar cache)")
    vehicle_208 = {"make": "Peugeot", "model": "208", "year": 2018}
    res2 = estimate_repair_cost(vehicle_208, det_lamp)
    print_test("Peugeot 208 + lamp_broken", res2, expected_source="manual_csv")

    # Test 3: Renault Symbol + lamp_broken (should use collected_csv exact, NOT similar cache)
    print("\n### Test 3: Renault Symbol + lamp_broken ###")
    print("Expected: collected_csv (exact collected should override similar cache)")
    vehicle_symbol = {"make": "Renault", "model": "Symbol", "year": 2017}
    res3 = estimate_repair_cost(vehicle_symbol, det_lamp)
    print_test("Renault Symbol + lamp_broken", res3, expected_source="collected_csv")

    # Test 4: Unknown vehicle + lamp_broken (should use rule_based, NOT similar cache)
    print("\n### Test 4: Unknown vehicle + lamp_broken ###")
    print("Expected: rule_based_fallback (no Any/Any for phare, should NOT use similar cache for unknown vehicle)")
    vehicle_unk = {"make": "Unknown", "model": "Unknown", "year": "Unknown"}
    res4 = estimate_repair_cost(vehicle_unk, det_lamp)
    print_test("Unknown vehicle + lamp_broken", res4, expected_source="rule_based_fallback")

    # Test 5: Peugeot 3008 + lamp_broken (should use similar_vehicle_cache from Peugeot 208)
    print("\n### Test 5: Peugeot 3008 + lamp_broken ###")
    print("Expected: similar_vehicle_cache (from Peugeot 208, different numeric model)")
    vehicle_3008 = {"make": "Peugeot", "model": "3008", "year": 2015}
    res5 = estimate_repair_cost(vehicle_3008, det_lamp)
    print_test("Peugeot 3008 + lamp_broken", res5, expected_source="similar_vehicle_cache")

    # Test 6: Renault Megane + lamp_broken (should check for similar Renault cache)
    print("\n### Test 6: Renault Megane + lamp_broken ###")
    print("Expected: manual_csv Any/Any (no valid Renault Symbol cache - has 0 price)")
    vehicle_megane = {"make": "Renault", "model": "Megane", "year": 2016}
    res6 = estimate_repair_cost(vehicle_megane, det_lamp)
    print_test("Renault Megane + lamp_broken", res6)

    # Test 7: Peugeot 207 + lamp_broken (closer to 208 than 206)
    print("\n### Test 7: Peugeot 207 + lamp_broken ###")
    print("Expected: similar_vehicle_cache (from Peugeot 208, similarity should be high)")
    vehicle_207 = {"make": "Peugeot", "model": "207", "year": 2012}
    res7 = estimate_repair_cost(vehicle_207, det_lamp)
    print_test("Peugeot 207 + lamp_broken", res7, expected_source="similar_vehicle_cache")

    print("\n" + "=" * 80)
    print("COLLECTED CSV TESTS (Regression)")
    print("=" * 80)
    
    # Test 8: Peugeot 205 + lamp_broken (should use collected_csv)
    vehicle_205 = {"make": "Peugeot", "model": "205", "year": 1990}
    res8 = estimate_repair_cost(vehicle_205, det_lamp)
    print_test("Test 8: Peugeot 205 + lamp_broken (EXPECT: collected_csv)", res8, expected_source="collected_csv")

    # Test 9: Renault Logan + lamp_broken (should use collected_csv)
    vehicle_logan = {"make": "Renault", "model": "Logan", "year": 2013}
    res9 = estimate_repair_cost(vehicle_logan, det_lamp)
    print_test("Test 9: Renault Logan + lamp_broken (EXPECT: collected_csv)", res9, expected_source="collected_csv")

    print("\n" + "=" * 80)
    print("MANUAL CSV & ANY/ANY TESTS (Regression)")
    print("=" * 80)

    # Test 10: Mercedes-Benz 204 + lamp_broken (should use manual_csv)
    vehicle_mb = {"make": "Mercedes-Benz", "model": "204", "year": 2012}
    res10 = estimate_repair_cost(vehicle_mb, det_lamp)
    print_test("Test 10: Mercedes-Benz 204 + lamp_broken (EXPECT: manual_csv)", res10, expected_source="manual_csv")

    # Test 11: Unknown vehicle + tire_flat (should use Any/Any from manual_csv)
    det_tire = [{"class_name": "tire_flat", "confidence": 0.95, "bbox_area_ratio": 0.25}]
    res11 = estimate_repair_cost(vehicle_unk, det_tire)
    print_test("Test 11: Unknown vehicle + tire_flat (EXPECT: manual_csv Any/Any)", res11, expected_source="manual_csv")

    print("\n" + "=" * 80)
    print("ORIGINAL REGRESSION TESTS")
    print("=" * 80)

    # Test 12: Class name normalization - 'lamp broken' (space)
    res12 = estimate_repair_cost(vehicle_208, [{"class_name": "lamp broken", "confidence": 0.90, "bbox_area_ratio": 0.15}])
    print_test("Test 12: Peugeot 208 + 'lamp broken' (space normalization)", res12)

    # Test 13: Unknown vehicle + scratch (no part needed)
    det_scratch = [{"class_name": "scratch", "confidence": 0.77, "bbox_area_ratio": 0.015}]
    res13 = estimate_repair_cost(vehicle_unk, det_scratch)
    print_test("Test 13: Unknown vehicle + scratch (no part needed)", res13)

    # Test 14: Unknown damage class
    det_alien = [{"class_name": "alien_laser_hole", "confidence": 0.99, "bbox_area_ratio": 0.1}]
    res14 = estimate_repair_cost(vehicle_unk, det_alien)
    print_test("Test 14: Unknown damage class 'alien_laser_hole'", res14)

    # Test 15: Empty detections list
    res15 = estimate_repair_cost(vehicle_208, [])
    print_test("Test 15: Empty detections list", res15)

    print("=" * 80)
    print("TEST SUITE COMPLETE")
    print("=" * 80)

if __name__ == "__main__":
    run_tests()

