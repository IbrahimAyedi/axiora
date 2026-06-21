import json
import csv
import os
import re
from datetime import datetime

# Define the base directory for the module to resolve absolute paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)

DAMAGE_CLASS_NORMALIZATION = {
    "dent": "dent",
    "scratch": "scratch",
    "crack": "crack",
    "glass shatter": "glass_shatter",
    "glass_shatter": "glass_shatter",
    "lamp broken": "lamp_broken",
    "lamp_broken": "lamp_broken",
    "tire flat": "tire_flat",
    "tire_flat": "tire_flat"
}

def load_json(filepath):
    if not os.path.exists(filepath):
        return {}
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def load_csv(filepath):
    rows = []
    if not os.path.exists(filepath):
        return rows
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows

def extract_numeric_model(model_str):
    """Extract numeric portion from model string for similarity comparison.
    
    Examples:
        '208' -> 208
        '206' -> 206
        'Civic' -> None
        'Symbol' -> None
    """
    if not model_str:
        return None
    # Extract first sequence of digits
    match = re.search(r'\d+', str(model_str))
    if match:
        try:
            return int(match.group())
        except ValueError:
            return None
    return None

def find_similar_vehicle_cached_price(vehicle, part_category):
    """Find similar vehicle price from SerpAPI cache.
    
    Logic:
    - Same make required
    - Same part_category required
    - Different model (exact model should already be handled)
    - Prefer closest numeric model distance
    - Ignore expired entries
    - Ignore invalid prices (<= 0)
    
    Returns:
        dict with keys: reference_make, reference_model, reference_year, 
                       reference_query, similarity_score, reference_price_tnd,
                       sources_json, confidence
        OR None if no suitable match found
    """
    cache_path = os.path.join(PROJECT_ROOT, 'data', 'serpapi_price_cache.csv')
    
    if not os.path.exists(cache_path):
        return None
    
    # Safely extract target vehicle info
    target_make = str(vehicle.get('make', '')).strip().lower()
    target_model = str(vehicle.get('model', '')).strip().lower()
    target_year = str(vehicle.get('year', '')).strip()
    part_category_lower = str(part_category).strip().lower()
    
    if not target_make or target_make in ['any', 'unknown', 'none']:
        return None
    
    # Load cache
    try:
        cache_rows = load_csv(cache_path)
    except Exception:
        return None
    
    if not cache_rows:
        return None
    
    now = datetime.now()
    candidates = []
    
    for row in cache_rows:
        try:
            # Extract cache entry info
            cache_make = str(row.get('make', '')).strip().lower()
            cache_model = str(row.get('model', '')).strip().lower()
            cache_year = str(row.get('year', '')).strip()
            cache_part_cat = str(row.get('part_category', '')).strip().lower()
            
            # Parse price
            try:
                cache_price = float(row.get('median_price_tnd', 0))
            except (ValueError, TypeError):
                cache_price = 0.0
            
            # Skip if price invalid
            if cache_price <= 0:
                continue
            
            # Check expiry
            expires_str = row.get('expires_at', '')
            if expires_str:
                try:
                    expires_dt = datetime.fromisoformat(expires_str)
                    if now > expires_dt:
                        continue  # Expired
                except Exception:
                    continue  # Invalid date format
            
            # MUST match make and part_category
            if cache_make != target_make:
                continue
            if cache_part_cat != part_category_lower:
                continue
            
            # MUST be different model (exact should be handled before this fallback)
            if cache_model == target_model:
                continue
            
            # Calculate similarity score
            target_numeric = extract_numeric_model(target_model)
            cache_numeric = extract_numeric_model(cache_model)
            
            if target_numeric is not None and cache_numeric is not None:
                # Numeric distance - smaller is better
                distance = abs(target_numeric - cache_numeric)
                # Convert to similarity score (higher is better)
                # Use inverse: score = 1 / (1 + distance)
                similarity_score = 1.0 / (1.0 + distance)
            else:
                # No numeric comparison possible - assign low similarity
                similarity_score = 0.3
            
            # Collect candidate
            candidates.append({
                'reference_make': row.get('make', 'N/A'),
                'reference_model': row.get('model', 'N/A'),
                'reference_year': cache_year,
                'reference_query': row.get('query', 'N/A'),
                'similarity_score': similarity_score,
                'reference_price_tnd': cache_price,
                'sources_json': row.get('sources_json', '[]'),
                'confidence': row.get('confidence', 'low')
            })
            
        except Exception:
            # Skip malformed rows
            continue
    
    if not candidates:
        return None
    
    # Return best candidate (highest similarity_score)
    best_candidate = max(candidates, key=lambda c: c['similarity_score'])
    return best_candidate

class CostEstimator:
    def __init__(self):
        self.damage_to_parts = load_json(os.path.join(BASE_DIR, 'damage_to_parts.json'))
        self.repair_rules = load_json(os.path.join(BASE_DIR, 'repair_rules.json'))
        self.class_severity_thresholds = load_json(os.path.join(BASE_DIR, 'class_severity_thresholds.json'))
        
        # Load both manual and collected price sources
        self.parts_prices_manual = load_csv(os.path.join(PROJECT_ROOT, 'data', 'parts_prices.csv'))
        self.parts_prices_collected = load_csv(os.path.join(PROJECT_ROOT, 'data', 'parts_prices_collected.csv'))
        
        # Normalize collected prices for consistency
        self._normalize_collected_prices()

    def _normalize_collected_prices(self):
        """Normalize collected prices to ensure consistent numeric values and handle duplicates"""
        for p in self.parts_prices_collected:
            # Ensure price_tnd is numeric
            try:
                p['price_tnd'] = float(p.get('price_tnd', 0))
            except (ValueError, TypeError):
                p['price_tnd'] = 0.0
            
            # Normalize quality_level if unknown
            if not p.get('quality_level') or p.get('quality_level', '').lower() in ['unknown', 'n/a', '']:
                p['quality_level'] = 'unknown'
            
            # Ensure required fields exist
            for field in ['source', 'source_url', 'image_url', 'make', 'model', 'part_category', 'part_name']:
                if field not in p:
                    p[field] = 'N/A'

    def normalize_class_name(self, class_name):
        if class_name is None:
            return "unknown"
        # Convert to string, strip extra spaces, and lowercase
        name_str = str(class_name).strip().lower()
        # Accept spaces, underscores, and hyphens (convert them to underscores)
        name_str = name_str.replace(" ", "_").replace("-", "_")
        
        # Valid internal names
        valid_classes = {"dent", "scratch", "crack", "glass_shatter", "lamp_broken", "tire_flat"}
        if name_str in valid_classes:
            return name_str
        return "unknown"

    def infer_severity(self, internal_class, bbox_area_ratio):
        if bbox_area_ratio is None:
            return "moyenne" # Safe fallback

        thresholds = self.class_severity_thresholds.get(internal_class)
        if not thresholds:
            return "moyenne"
        
        bas_max = thresholds.get("bas_max", 0.05)
        moyenne_max = thresholds.get("moyenne_max", 0.15)
        
        if bbox_area_ratio <= bas_max:
            return "bas"
        elif bbox_area_ratio <= moyenne_max:
            return "moyenne"
        else:
            return "haut"

    def find_part_prices(self, make, model, part_category):
        """
        Find part prices with priority order:
        1. Collected CSV exact match
        2. Manual CSV exact match  
        3. Similar vehicle cache fallback (NEW)
        4. Manual CSV Any/Any fallback
        5. Empty list (rule-based fallback will handle)
        
        Returns: (matches_list, data_origin, similar_vehicle_info)
        data_origin: 'collected_csv' | 'manual_csv' | 'similar_vehicle_cache' | None
        similar_vehicle_info: dict if data_origin == 'similar_vehicle_cache', else None
        """
        # Ensure safe string values for make, model, part_category to avoid AttributeError
        make_str = str(make).strip() if make is not None else "Any"
        model_str = str(model).strip() if model is not None else "Any"
        part_category_str = str(part_category).strip().lower() if part_category is not None else "unknown"
        
        if not make_str or make_str.lower() == "none":
            make_str = "Any"
        if not model_str or model_str.lower() == "none":
            model_str = "Any"

        def safe_lower(val):
            if val is None:
                return ""
            return str(val).strip().lower()

        # PRIORITY 1: Collected CSV exact match
        collected_matches = []
        for p in self.parts_prices_collected:
            p_make = safe_lower(p.get('make'))
            p_model = safe_lower(p.get('model'))
            p_cat = safe_lower(p.get('part_category'))
            
            if p_make == make_str.lower() and p_model == model_str.lower() and p_cat == part_category_str:
                collected_matches.append(p)

        if collected_matches:
            # Remove duplicates based on price (keep first occurrence)
            unique_collected = []
            seen_prices = set()
            for p in collected_matches:
                price = p.get('price_tnd', 0)
                if price not in seen_prices:
                    seen_prices.add(price)
                    unique_collected.append(p)
            
            if unique_collected:
                return (unique_collected, 'collected_csv', None)

        # PRIORITY 2: Manual CSV exact match
        exact_matches = []
        for p in self.parts_prices_manual:
            p_make = safe_lower(p.get('make'))
            p_model = safe_lower(p.get('model'))
            p_cat = safe_lower(p.get('part_category'))
            
            if p_make == make_str.lower() and p_model == model_str.lower() and p_cat == part_category_str:
                exact_matches.append(p)

        if len(exact_matches) >= 3:
            return (exact_matches, 'manual_csv', None)

        # PRIORITY 3: Similar vehicle cache fallback (NEW)
        vehicle_dict = {'make': make_str, 'model': model_str, 'year': 'Any'}
        similar_cache = find_similar_vehicle_cached_price(vehicle_dict, part_category_str)
        
        if similar_cache:
            # Generate synthetic price options based on cached price
            reference_price = similar_cache['reference_price_tnd']
            
            synthetic_parts = [
                {
                    'price_tnd': round(reference_price * 0.85, 2),
                    'quality_level': 'bas',
                    'part_name': f"Similar vehicle price (économique)",
                    'source': 'serpapi_cache',
                    'make': similar_cache['reference_make'],
                    'model': similar_cache['reference_model'],
                    'year': similar_cache['reference_year'],
                    'part_category': part_category_str
                },
                {
                    'price_tnd': reference_price,
                    'quality_level': 'moyenne',
                    'part_name': f"Similar vehicle price (standard)",
                    'source': 'serpapi_cache',
                    'make': similar_cache['reference_make'],
                    'model': similar_cache['reference_model'],
                    'year': similar_cache['reference_year'],
                    'part_category': part_category_str
                },
                {
                    'price_tnd': round(reference_price * 1.25, 2),
                    'quality_level': 'haut',
                    'part_name': f"Similar vehicle price (premium)",
                    'source': 'serpapi_cache',
                    'make': similar_cache['reference_make'],
                    'model': similar_cache['reference_model'],
                    'year': similar_cache['reference_year'],
                    'part_category': part_category_str
                }
            ]
            return (synthetic_parts, 'similar_vehicle_cache', similar_cache)

        # PRIORITY 4: Manual CSV Any/Any fallback
        fallback_matches = []
        for p in self.parts_prices_manual:
            p_make = safe_lower(p.get('make'))
            p_model = safe_lower(p.get('model'))
            p_cat = safe_lower(p.get('part_category'))
            
            if p_make == 'any' and p_model == 'any' and p_cat == part_category_str:
                fallback_matches.append(p)
                
        if fallback_matches:
            return (fallback_matches, 'manual_csv', None)
        
        # PRIORITY 5: No CSV data found
        return ([], None, None)
    
    def derive_quality_levels_from_collected(self, collected_parts):
        """
        Derive bas/moyenne/haut quality levels from collected prices with unknown quality_level.
        
        Returns: dict with keys 'bas', 'moyenne', 'haut' mapping to part data, plus 'warnings' list
        """
        warnings = []
        
        if not collected_parts:
            return {'bas': None, 'moyenne': None, 'haut': None, 'warnings': warnings}
        
        # Sort by price ascending
        sorted_parts = sorted(collected_parts, key=lambda x: x.get('price_tnd', 0))
        count = len(sorted_parts)
        
        result = {'bas': None, 'moyenne': None, 'haut': None, 'warnings': warnings}
        
        if count >= 3:
            # Use lowest, median, highest
            result['bas'] = sorted_parts[0].copy()
            result['bas']['quality_level'] = 'bas'
            
            result['moyenne'] = sorted_parts[count // 2].copy()
            result['moyenne']['quality_level'] = 'moyenne'
            
            result['haut'] = sorted_parts[-1].copy()
            result['haut']['quality_level'] = 'haut'
            
        elif count == 2:
            # Use lowest as bas, highest as haut, derive moyenne
            result['bas'] = sorted_parts[0].copy()
            result['bas']['quality_level'] = 'bas'
            
            result['haut'] = sorted_parts[1].copy()
            result['haut']['quality_level'] = 'haut'
            
            # Derive moyenne as average
            avg_price = (sorted_parts[0]['price_tnd'] + sorted_parts[1]['price_tnd']) / 2
            result['moyenne'] = sorted_parts[0].copy()  # Copy metadata from first
            result['moyenne']['price_tnd'] = avg_price
            result['moyenne']['quality_level'] = 'moyenne'
            result['moyenne']['part_name'] = result['moyenne'].get('part_name', 'N/A') + ' (moyenne)'
            
            warnings.append("Only two collected prices found; moyenne derived as average.")
            
        elif count == 1:
            # Use single price as moyenne, derive bas/haut
            base_price = sorted_parts[0]['price_tnd']
            
            result['bas'] = sorted_parts[0].copy()
            result['bas']['price_tnd'] = round(base_price * 0.85, 2)
            result['bas']['quality_level'] = 'bas'
            result['bas']['part_name'] = result['bas'].get('part_name', 'N/A') + ' (économique)'
            
            result['moyenne'] = sorted_parts[0].copy()
            result['moyenne']['quality_level'] = 'moyenne'
            
            result['haut'] = sorted_parts[0].copy()
            result['haut']['price_tnd'] = round(base_price * 1.25, 2)
            result['haut']['quality_level'] = 'haut'
            result['haut']['part_name'] = result['haut'].get('part_name', 'N/A') + ' (premium)'
            
            warnings.append("Only one collected price found; bas/haut derived from moyenne.")
        
        result['warnings'] = warnings
        return result

    def estimate_repair_cost(self, vehicle, detections, region="Tunis"):
        # Ensure vehicle is a dictionary safely
        if not isinstance(vehicle, dict):
            vehicle = {}
            
        make_val = vehicle.get("make")
        model_val = vehicle.get("model")
        year_val = vehicle.get("year")
        
        make_str = str(make_val).strip() if make_val is not None else "Any"
        model_str = str(model_val).strip() if model_val is not None else "Any"
        year_str = str(year_val).strip() if year_val is not None else "Any"
        
        if not make_str or make_str.lower() == "none":
            make_str = "Any"
        if not model_str or model_str.lower() == "none":
            model_str = "Any"
        if not year_str or year_str.lower() == "none":
            year_str = "Any"

        # Safely wrap detections list
        if detections is None:
            detections = []

        results = []

        for det in detections:
            if not isinstance(det, dict):
                continue
                
            original_class = det.get("class_name")
            confidence = det.get("confidence", 0.0)
            bbox_area_ratio = det.get("bbox_area_ratio")
            
            internal_class = self.normalize_class_name(original_class)
            warnings = []

            if internal_class == "unknown":
                warnings.append(f"Unknown class name '{original_class}' skipped.")
                results.append({
                    "original_class_name": original_class,
                    "normalized_class_name": internal_class,
                    "confidence": confidence,
                    "warnings": warnings
                })
                continue

            severity = self.infer_severity(internal_class, bbox_area_ratio)
            if bbox_area_ratio is None:
                warnings.append("bbox_area_ratio is missing; defaulted to 'moyenne' severity.")

            mapping = self.damage_to_parts.get(internal_class, {})
            repair_strategy = mapping.get("repair_strategy", "unknown")
            part_keywords = mapping.get("part_keywords", [])
            needs_part = mapping.get("needs_part", False)

            part_category = part_keywords[0] if part_keywords else "unknown"

            # Get Labor/Paint Rules
            rules = self.repair_rules.get(internal_class, {})
            labor_costs = rules.get("labor", {"bas": 0, "moyenne": 0, "haut": 0})
            paint_costs = rules.get("paint", {"bas": 0, "moyenne": 0, "haut": 0})

            # Get Part Prices with priority logic
            part_options = []
            data_origin = None
            similar_vehicle_info = None
            collected_derivation_warnings = []
            
            if needs_part:
                part_options, data_origin, similar_vehicle_info = self.find_part_prices(make_str, model_str, part_category)
                
                # Add warning for similar vehicle cache usage
                if data_origin == 'similar_vehicle_cache' and similar_vehicle_info:
                    ref_vehicle = f"{similar_vehicle_info['reference_make']} {similar_vehicle_info['reference_model']}"
                    similarity = similar_vehicle_info.get('similarity_score', 0)
                    warnings.append(
                        f"Exact price not found. Used cached price from similar vehicle ({ref_vehicle}) "
                        f"as approximate fallback (similarity: {similarity:.2f})."
                    )
                
                if not part_options and not data_origin:
                    warnings.append(f"No parts found for {make_str} {model_str} {part_category}. Falling back to 0 TND for part.")
                    data_origin = "rule_based_fallback"

            # Build options for each quality level
            options = {}
            
            # If we got collected CSV data with unknown quality levels, derive bas/moyenne/haut
            if data_origin == 'collected_csv' and part_options:
                derived = self.derive_quality_levels_from_collected(part_options)
                collected_derivation_warnings = derived.get('warnings', [])
                warnings.extend(collected_derivation_warnings)
                
                for level in ["bas", "moyenne", "haut"]:
                    labor = labor_costs.get(level, 0)
                    paint = paint_costs.get(level, 0)
                    
                    derived_part = derived.get(level)
                    
                    if derived_part:
                        part_price = derived_part.get('price_tnd', 0)
                        part_name = derived_part.get('part_name', 'N/A')
                        part_brand = derived_part.get('part_brand', 'N/A')
                        reference = derived_part.get('reference', 'N/A')
                        source = derived_part.get('source', 'karhabtk')
                        source_url = derived_part.get('source_url', 'N/A')
                        image_url = derived_part.get('image_url', 'N/A')
                        availability = derived_part.get('availability', 'N/A')
                        quality_level = derived_part.get('quality_level', level)
                    else:
                        part_price = 0
                        part_name = "N/A"
                        part_brand = "N/A"
                        reference = "N/A"
                        source = "collected_csv"
                        source_url = "N/A"
                        image_url = "N/A"
                        availability = "N/A"
                        quality_level = level
                    
                    options[level] = {
                        "label": "Économique" if level == "bas" else "Standard" if level == "moyenne" else "Premium",
                        "part_name": part_name,
                        "part_brand": part_brand,
                        "reference": reference,
                        "part_price": part_price,
                        "labor": labor,
                        "paint": paint,
                        "total": part_price + labor + paint,
                        "source": source,
                        "source_url": source_url,
                        "image_url": image_url,
                        "availability": availability,
                        "quality_level": quality_level
                    }
            elif data_origin == 'similar_vehicle_cache' and part_options and similar_vehicle_info:
                # Similar vehicle cache fallback with synthetic price range
                for level in ["bas", "moyenne", "haut"]:
                    labor = labor_costs.get(level, 0)
                    paint = paint_costs.get(level, 0)
                    
                    matching_part = next((p for p in part_options if p.get('quality_level', '').lower() == level), None)
                    
                    if matching_part:
                        part_price = matching_part.get('price_tnd', 0)
                        part_name = matching_part.get('part_name', 'N/A')
                        source = matching_part.get('source', 'serpapi_cache')
                        part_brand = "N/A"
                        reference = "N/A"
                        source_url = "N/A"
                        image_url = "N/A"
                        availability = "approximate"
                        quality_level = level
                    else:
                        part_price = 0
                        part_name = "N/A"
                        part_brand = "N/A"
                        reference = "N/A"
                        source = "serpapi_cache"
                        source_url = "N/A"
                        image_url = "N/A"
                        availability = "approximate"
                        quality_level = level
                    
                    options[level] = {
                        "label": "Économique" if level == "bas" else "Standard" if level == "moyenne" else "Premium",
                        "part_name": part_name,
                        "part_brand": part_brand,
                        "reference": reference,
                        "part_price": part_price,
                        "labor": labor,
                        "paint": paint,
                        "total": part_price + labor + paint,
                        "source": source,
                        "source_url": source_url,
                        "image_url": image_url,
                        "availability": availability,
                        "quality_level": quality_level,
                        "reference_vehicle": f"{similar_vehicle_info['reference_make']} {similar_vehicle_info['reference_model']}",
                        "similarity_score": similar_vehicle_info.get('similarity_score', 0),
                        "confidence": "low"
                    }
            else:
                # Manual CSV or rule-based fallback logic (original behavior)
                for level in ["bas", "moyenne", "haut"]:
                    labor = labor_costs.get(level, 0)
                    paint = paint_costs.get(level, 0)
                    
                    # Default empty part info
                    part_price = 0
                    part_name = "N/A"
                    part_brand = "N/A"
                    reference = "N/A"
                    source = "manual_prototype" if data_origin == 'manual_csv' else "rule_based_fallback"
                    source_url = "N/A"
                    image_url = "N/A"
                    availability = "N/A"
                    quality_level = level

                    if needs_part and part_options:
                        # Find matching quality level part in our CSV matches
                        matching_part = next((p for p in part_options if p.get('quality_level', '').lower() == level), None)
                        if matching_part:
                            try:
                                part_price = float(matching_part.get("price_tnd", 0))
                            except ValueError:
                                part_price = 0
                            part_name = matching_part.get("part_name", "N/A")
                            part_brand = matching_part.get("part_brand", "N/A")
                            reference = matching_part.get("reference", "N/A")
                            source = matching_part.get("source", "manual_prototype")
                            source_url = matching_part.get("source_url", "N/A")
                            image_url = matching_part.get("image_url", "N/A")
                            availability = matching_part.get("availability", "N/A")
                            quality_level = matching_part.get("quality_level", level)
                            
                            if matching_part.get("make", "Any") == "Any":
                                if "Using generic Any/Any part price" not in ' '.join(warnings):
                                    warnings.append(f"Using generic Any/Any part price for {level}.")

                    options[level] = {
                        "label": "Économique" if level == "bas" else "Standard" if level == "moyenne" else "Premium",
                        "part_name": part_name,
                        "part_brand": part_brand,
                        "reference": reference,
                        "part_price": part_price,
                        "labor": labor,
                        "paint": paint,
                        "total": part_price + labor + paint,
                        "source": source,
                        "source_url": source_url,
                        "image_url": image_url,
                        "availability": availability,
                        "quality_level": quality_level
                    }

            # Recommendation defaults to the option that matches severity
            recommended_level = severity

            estimation_item = {
                "original_class_name": original_class,
                "normalized_class_name": internal_class,
                "confidence": confidence,
                "severity": severity,
                "repair_strategy": repair_strategy,
                "part_category": part_category,
                "part_keywords": part_keywords,
                "options": options,
                "recommended": options.get(recommended_level),
                "recommended_level": recommended_level,
                "data_source": data_origin if data_origin else "rule_based_fallback",
                "warnings": list(set(warnings)) # deduplicate
            }

            results.append(estimation_item)

        return {
            "currency": "TND",
            "vehicle": {
                "make": make_str,
                "model": model_str,
                "year": year_str
            },
            "region": region,
            "estimations": results,
            "warning": "Estimation indicative à confirmer par un garage."
        }

# Singleton-like instance for convenience if needed
estimator_instance = None

def estimate_repair_cost(vehicle: dict, detections: list, region: str = "Tunis") -> dict:
    global estimator_instance
    if estimator_instance is None:
        estimator_instance = CostEstimator()
    return estimator_instance.estimate_repair_cost(vehicle, detections, region)

