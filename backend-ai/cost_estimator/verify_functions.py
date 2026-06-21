from estimator import find_similar_vehicle_cached_price, extract_numeric_model

print('✓ Functions imported successfully')
print(f'✓ extract_numeric_model("206") = {extract_numeric_model("206")}')
print(f'✓ extract_numeric_model("208") = {extract_numeric_model("208")}')
print(f'✓ extract_numeric_model("Civic") = {extract_numeric_model("Civic")}')

# Test similarity
vehicle_206 = {"make": "Peugeot", "model": "206", "year": "2010"}
result = find_similar_vehicle_cached_price(vehicle_206, "phare")

if result:
    print(f'\n✓ Similar cache lookup successful for Peugeot 206')
    print(f'  Reference: {result["reference_make"]} {result["reference_model"]}')
    print(f'  Price: {result["reference_price_tnd"]} TND')
    print(f'  Similarity: {result["similarity_score"]:.3f}')
else:
    print('\n✗ No similar cache found')
