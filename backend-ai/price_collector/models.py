import os
import csv
from dataclasses import dataclass
from typing import Optional

@dataclass
class CollectedPart:
    source: str
    source_url: str
    image_url: str
    make: str
    model: str
    year: int
    part_category: str
    part_name: str
    part_brand: str
    reference: str
    price_tnd: float
    availability: str
    condition: str
    quality_level: str
    collected_at: str
