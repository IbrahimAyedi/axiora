import csv
import os
import dataclasses
from .models import CollectedPart

def save_parts_to_csv(parts: list, output_path: str) -> None:
    file_exists = os.path.isfile(output_path)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    fieldnames = [f.name for f in dataclasses.fields(CollectedPart)]
    
    with open(output_path, mode='a', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if not file_exists:
            writer.writeheader()
            
        if not parts:
            return
            
        for part in parts:
            if isinstance(part, CollectedPart):
                writer.writerow(dataclasses.asdict(part))
            elif isinstance(part, dict):
                # Only write fields that belong to CollectedPart
                row = {k: v for k, v in part.items() if k in fieldnames}
                # Fill missing fields with empty strings
                for field in fieldnames:
                    if field not in row:
                        row[field] = ""
                writer.writerow(row)
