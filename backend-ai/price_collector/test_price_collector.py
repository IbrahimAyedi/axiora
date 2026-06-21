import json
import os
import dataclasses
from price_collector.sources.autopart import search_autopart
from price_collector.sources.sosautoparts import search_sosautoparts
from price_collector.sources.piecesautos import search_piecesautos
from price_collector.sources.karhabtk import search_karhabtk
from price_collector.sources.ballouchi import search_ballouchi
from price_collector.storage import save_parts_to_csv

CLEAR_OUTPUT_BEFORE_TEST = True

def run_test():
    test_cases = [
        {"name": "Case 1 (Target)", "make": "Peugeot", "model": "208", "year": "2018", "part_category": "phare"},
        {"name": "Case 2 (Validation 205)", "make": "Peugeot", "model": "205", "year": "Any", "part_category": "phare"},
        {"name": "Case 3 (Validation Logan)", "make": "Renault", "model": "Logan", "year": "Any", "part_category": "phare"},
        {"name": "Case 4 (Validation Symbol)", "make": "Renault", "model": "Symbol", "year": "2017", "part_category": "phare"}
    ]
    
    csv_path = os.path.join("data", "parts_prices_collected.csv")
    if CLEAR_OUTPUT_BEFORE_TEST and os.path.exists(csv_path):
        print(f"Clearing output CSV: {csv_path}")
        os.remove(csv_path)
    
    print("Starting multi-case price collector test...")
    
    all_results = []
    
    for case in test_cases:
        print(f"\n{'='*50}")
        print(f"Running {case['name']}")
        print(f"Target: {case['part_category']} for {case['make']} {case['model']} {case['year']}")
        print(f"{'='*50}")
        
        # We focus primarily on Karhabtk as per requirements, but we'll run others too
        case_results = []
        
        print("\nQuerying Karhabtk.tn...")
        results_kb = search_karhabtk(
            make=case["make"],
            model=case["model"],
            year=case["year"],
            part_category=case["part_category"]
        )
        print(f"Karhabtk filtered relevant results: {len(results_kb)}")
        if results_kb:
            print("First 5 Karhabtk results:")
            for r in results_kb[:5]:
                print(json.dumps(dataclasses.asdict(r), indent=2, ensure_ascii=False))
        else:
            print("Karhabtk returned products, but none matched the requested part category.")
        case_results.extend(results_kb)
        
        print("\nQuerying AutoPart.tn...")
        results_ap = search_autopart(
            make=case["make"],
            model=case["model"],
            year=case["year"],
            part_category=case["part_category"]
        )
        print(f"AutoPart.tn filtered relevant results: {len(results_ap)}")
        case_results.extend(results_ap)
        
        print("\nQuerying SOSAutoParts.tn...")
        results_sos = search_sosautoparts(
            make=case["make"],
            model=case["model"],
            year=case["year"],
            part_category=case["part_category"]
        )
        print(f"SOSAutoParts filtered relevant results: {len(results_sos)}")
        case_results.extend(results_sos)

        print("\nQuerying PiecesAutos.tn...")
        results_pa = search_piecesautos(
            make=case["make"],
            model=case["model"],
            year=case["year"],
            part_category=case["part_category"]
        )
        print(f"PiecesAutos filtered relevant results: {len(results_pa)}")
        case_results.extend(results_pa)
        
        print("\nQuerying Ballouchi.com...")
        results_ballouchi = search_ballouchi(
            make=case["make"],
            model=case["model"],
            year=case["year"],
            part_category=case["part_category"]
        )
        print(f"Ballouchi filtered relevant results: {len(results_ballouchi)}")
        if results_ballouchi:
            print("First 5 Ballouchi results:")
            for r in results_ballouchi[:5]:
                print(json.dumps(dataclasses.asdict(r), indent=2, ensure_ascii=False))
        else:
            print("Ballouchi returned 0 results or was blocked.")
        case_results.extend(results_ballouchi)
        
        print(f"\n{case['name']} Total relevant results found: {len(case_results)}")
        all_results.extend(case_results)

    # Validation
    if all_results:
        print("\nValidating results...")
        for idx, r in enumerate(all_results):
            if r.source not in ["autopart", "sosautoparts", "piecesautos", "karhabtk", "ballouchi"]:
                print(f"Warning (Result {idx}): source is not expected")
            if not r.make or not r.model or not r.year:
                print(f"Warning (Result {idx}): vehicle info missing")
            if not r.part_category:
                print(f"Warning (Result {idx}): part_category missing")
            if not r.part_name or r.part_name == "N/A":
                print(f"Warning (Result {idx}): part_name is empty or N/A")
            if not isinstance(r.price_tnd, (int, float)):
                print(f"Warning (Result {idx}): price_tnd is not numeric")
            if not r.source_url or r.source_url == "N/A":
                print(f"Warning (Result {idx}): source_url missing")
            if not r.image_url or r.image_url == "N/A":
                print(f"Warning (Result {idx}): image_url missing")
    
    # Storage
    csv_existed = os.path.exists(csv_path)
    
    print(f"\nSaving to CSV: {csv_path}")
    save_parts_to_csv(all_results, csv_path)
    
    if csv_existed:
        print("CSV already existed. Rows appended.")
    else:
        print("CSV did not exist. Created new file with headers.")
        
    print("\nTest completed.")

if __name__ == "__main__":
    run_test()


