
import os, json, csv, hashlib, collections, sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
from pathlib import Path

BASE = Path(r"c:\Users\ayedi\OneDrive\Desktop\car_damage_yolo_clean (pfa)")
COCO_BASE = BASE / "CarDD_release" / "CarDD_release" / "CarDD_COCO"
SOD_BASE  = BASE / "CarDD_release" / "CarDD_release" / "CarDD_SOD"
OUT       = BASE / "analysis_output"
OUT.mkdir(exist_ok=True)

print("="*70)
print("STEP 1 — FULL FILE STRUCTURE EXPLORATION")
print("="*70)

# Walk entire tree
all_files = []
for p in BASE.rglob("*"):
    if p.is_file():
        all_files.append(p)

ext_counter = collections.Counter(p.suffix.lower() for p in all_files)
print(f"Total files found: {len(all_files)}")
for ext, cnt in ext_counter.most_common():
    name = ext if ext else "(no extension)"
    print(f"  {name:15s} : {cnt}")

print()
print("Directory tree (simplified):")
for p in sorted(BASE.rglob("*")):
    if p.is_dir():
        depth = len(p.relative_to(BASE).parts)
        indent = "  " * depth
        try:
            fc = len([x for x in p.iterdir()])
        except:
            fc = "?"
        print(f"{indent}[DIR] {p.name}/  ({fc} items)")

print()
print("="*70)
print("STEP 2 — ANNOTATION STRUCTURE DETECTION")
print("="*70)

# Read the 3 COCO JSON files
ann_dir = COCO_BASE / "annotations"
coco_files = {
    "train": ann_dir / "instances_train2017.json",
    "val":   ann_dir / "instances_val2017.json",
    "test":  ann_dir / "instances_test2017.json",
}

all_coco_data = {}
for split, fpath in coco_files.items():
    print(f"\n--- COCO {split} ({fpath.name}) ---")
    with open(fpath, "r", encoding="utf-8") as f:
        data = json.load(f)
    all_coco_data[split] = data

    top_keys = list(data.keys())
    print(f"  Top-level keys: {top_keys}")
    if "info" in data:
        print(f"  info: {data['info']}")
    if "licenses" in data:
        print(f"  licenses count: {len(data['licenses'])}")
    if "images" in data:
        print(f"  images count: {len(data['images'])}")
        if data["images"]:
            sample = data["images"][0]
            print(f"  image sample keys: {list(sample.keys())}")
            print(f"  image sample: {sample}")
    if "annotations" in data:
        print(f"  annotations count: {len(data['annotations'])}")
        if data["annotations"]:
            sample = data["annotations"][0]
            print(f"  annotation sample keys: {list(sample.keys())}")
            print(f"  annotation sample: {sample}")
    if "categories" in data:
        print(f"  categories: {data['categories']}")

print()
print("="*70)
print("STEP 3 — DETAILED IMAGE ANALYSIS")
print("="*70)

# Count images per split/folder
splits = {
    "COCO_train": COCO_BASE / "train2017",
    "COCO_val":   COCO_BASE / "val2017",
    "COCO_test":  COCO_BASE / "test2017",
    "SOD_TR_Image":   SOD_BASE / "CarDD-TR" / "CarDD-TR-Image",
    "SOD_TR_Mask":    SOD_BASE / "CarDD-TR" / "CarDD-TR-Mask",
    "SOD_TR_Edge":    SOD_BASE / "CarDD-TR" / "CarDD-TR-Edge",
    "SOD_TE_Image":   SOD_BASE / "CarDD-TE" / "CarDD-TE-Image",
    "SOD_TE_Mask":    SOD_BASE / "CarDD-TE" / "CarDD-TE-Mask",
    "SOD_TE_Edge":    SOD_BASE / "CarDD-TE" / "CarDD-TE-Edge",
    "SOD_VAL_Image":  SOD_BASE / "CarDD-VAL" / "CarDD-VAL-Image",
    "SOD_VAL_Mask":   SOD_BASE / "CarDD-VAL" / "CarDD-VAL-Mask",
    "SOD_VAL_Edge":   SOD_BASE / "CarDD-VAL" / "CarDD-VAL-Edge",
}

all_image_info = {}
for split_name, folder in splits.items():
    if not folder.exists():
        print(f"  [MISSING] {split_name}: {folder}")
        continue
    files = list(folder.iterdir())
    imgs = [f for f in files if f.suffix.lower() in (".jpg",".jpeg",".png",".bmp",".tif",".tiff")]
    print(f"\n  {split_name}: {len(imgs)} images")
    if imgs:
        sizes = [f.stat().st_size for f in imgs]
        print(f"    file size: min={min(sizes)//1024}KB, max={max(sizes)//1024}KB, avg={sum(sizes)//len(sizes)//1024}KB")
        exts = collections.Counter(f.suffix.lower() for f in imgs)
        print(f"    extensions: {dict(exts)}")
        # Sample filenames
        print(f"    sample names: {[f.name for f in imgs[:5]]}")
        all_image_info[split_name] = {
            "count": len(imgs),
            "min_bytes": min(sizes),
            "max_bytes": max(sizes),
            "avg_bytes": sum(sizes)//len(imgs),
            "extensions": dict(exts),
            "sample_names": [f.name for f in imgs[:5]],
        }

print()
print("="*70)
print("STEP 4 — ANNOTATION ANALYSIS (COCO FORMAT)")
print("="*70)

# Deep COCO analysis
for split, data in all_coco_data.items():
    print(f"\n=== {split.upper()} SPLIT ===")
    
    images    = data.get("images", [])
    anns      = data.get("annotations", [])
    cats      = data.get("categories", [])
    
    img_ids   = {img["id"] for img in images}
    ann_img_ids = {ann["image_id"] for ann in anns}
    
    imgs_without_ann  = img_ids - ann_img_ids
    anns_without_imgs = ann_img_ids - img_ids
    
    print(f"  Total images:              {len(images)}")
    print(f"  Total annotations:         {len(anns)}")
    print(f"  Images WITHOUT annotations:{len(imgs_without_ann)}")
    print(f"  Annotations WITHOUT images:{len(anns_without_imgs)}")
    print(f"  Categories:                {cats}")
    
    # Per-category count
    cat_counts = collections.Counter(ann["category_id"] for ann in anns)
    cat_map    = {cat["id"]: cat["name"] for cat in cats}
    print(f"  Annotations per category:")
    for cid, cnt in sorted(cat_counts.items()):
        print(f"    [{cid}] {cat_map.get(cid,'unknown'):30s} → {cnt}")
    
    # BBox analysis
    print(f"  Bbox analysis:")
    areas = []
    invalid_bboxes = 0
    out_of_bounds  = 0
    img_dims = {img["id"]: (img.get("width",0), img.get("height",0)) for img in images}
    
    for ann in anns:
        if "bbox" not in ann:
            continue
        x,y,w,h = ann["bbox"]
        area = w*h
        areas.append(area)
        if w<=0 or h<=0:
            invalid_bboxes += 1
        if img_dims.get(ann["image_id"]):
            iw, ih = img_dims[ann["image_id"]]
            if x<0 or y<0 or (x+w)>iw or (y+h)>ih:
                out_of_bounds += 1
    
    if areas:
        print(f"    min area:      {min(areas):.1f}")
        print(f"    max area:      {max(areas):.1f}")
        print(f"    avg area:      {sum(areas)/len(areas):.1f}")
        print(f"    invalid bboxes (w<=0 or h<=0): {invalid_bboxes}")
        print(f"    out-of-bounds bboxes:          {out_of_bounds}")
    
    # Segmentation
    has_seg = sum(1 for ann in anns if ann.get("segmentation"))
    print(f"  Has segmentation: {has_seg} / {len(anns)}")
    
    # image resolution from COCO metadata
    widths  = [img.get("width",0)  for img in images]
    heights = [img.get("height",0) for img in images]
    if widths:
        print(f"  Image widths:  min={min(widths)}, max={max(widths)}, avg={sum(widths)//len(widths)}")
        print(f"  Image heights: min={min(heights)}, max={max(heights)}, avg={sum(heights)//len(heights)}")
    
    # Check for duplicate image IDs
    id_counts = collections.Counter(img["id"] for img in images)
    dup_ids = {k:v for k,v in id_counts.items() if v>1}
    if dup_ids:
        print(f"  [WARNING] Duplicate image IDs: {len(dup_ids)}")
    else:
        print(f"  No duplicate image IDs.")

print()
print("="*70)
print("STEP 5 — FILENAME DUPLICATES ACROSS COCO SPLITS")
print("="*70)

for split, data in all_coco_data.items():
    fnames = [img["file_name"] for img in data.get("images",[])]
    dup = [f for f,c in collections.Counter(fnames).items() if c>1]
    print(f"  {split}: {len(dup)} duplicate filenames")
    if dup:
        print(f"    examples: {dup[:5]}")

# Cross-split filename overlap
train_fnames = {img["file_name"] for img in all_coco_data.get("train",{}).get("images",[])}
val_fnames   = {img["file_name"] for img in all_coco_data.get("val",{}).get("images",[])}
test_fnames  = {img["file_name"] for img in all_coco_data.get("test",{}).get("images",[])}
tv_overlap = train_fnames & val_fnames
tt_overlap = train_fnames & test_fnames
vt_overlap = val_fnames & test_fnames
print(f"  Train∩Val overlap: {len(tv_overlap)}")
print(f"  Train∩Test overlap: {len(tt_overlap)}")
print(f"  Val∩Test overlap: {len(vt_overlap)}")

print()
print("="*70)
print("STEP 6 — SOD FORMAT ANALYSIS")
print("="*70)

# Read .lst files
lst_files = {
    "train": SOD_BASE / "CarDD-TR" / "train_pair.lst",
    "val":   SOD_BASE / "CarDD-VAL" / "val.lst",
    "test":  SOD_BASE / "CarDD-TE"  / "test.lst",
}
for split, lst_path in lst_files.items():
    if lst_path.exists():
        lines = lst_path.read_text(encoding="utf-8", errors="replace").strip().splitlines()
        print(f"\n  {split} .lst ({lst_path.name}): {len(lines)} lines")
        # Sample lines
        for ln in lines[:5]:
            print(f"    {ln}")
        # Detect format
        if lines:
            parts = lines[0].split()
            print(f"    Columns per line: {len(parts)}")

print()
print("="*70)
print("STEP 7 — CLASS & CATEGORY DEEP UNDERSTANDING")
print("="*70)

# Pull all categories (same across splits, but verify)
all_cats = {}
for split, data in all_coco_data.items():
    for cat in data.get("categories",[]):
        cid = cat["id"]
        if cid not in all_cats:
            all_cats[cid] = cat
        else:
            if all_cats[cid] != cat:
                print(f"  [WARNING] Category {cid} differs across splits!")

print(f"  Unique categories across ALL splits: {len(all_cats)}")
for cid, cat in sorted(all_cats.items()):
    print(f"    id={cid:3d}  name={cat['name']:40s}  supercategory={cat.get('supercategory','')}")

# Count annotations per class per split
print(f"\n  Annotation count per class per split:")
header = f"{'Class':35s} | {'Train':8s} | {'Val':8s} | {'Test':8s} | {'Total':8s}"
print(f"  {header}")
print(f"  {'-'*len(header)}")
for cid, cat in sorted(all_cats.items()):
    counts = {}
    for split, data in all_coco_data.items():
        cnt = sum(1 for ann in data.get("annotations",[]) if ann["category_id"]==cid)
        counts[split] = cnt
    total = sum(counts.values())
    print(f"  {cat['name']:35s} | {counts.get('train',0):8d} | {counts.get('val',0):8d} | {counts.get('test',0):8d} | {total:8d}")

print()
print("="*70)
print("STEP 8 — GENERATING OUTPUT FILES")
print("="*70)

# --- dataset_summary.json ---
summary_data = {
    "dataset_name": "CarDD (Car Damage Detection Dataset)",
    "root_path": str(BASE),
    "formats_detected": ["COCO (instance detection/segmentation)", "SOD (Salient Object Detection)"],
    "splits": {},
    "categories": [],
    "total_images_coco": 0,
    "total_annotations_coco": 0,
    "image_metadata_source": "COCO JSON files",
}

cat_dist_rows = []
for cid, cat in sorted(all_cats.items()):
    row = {"id": cid, "name": cat["name"], "supercategory": cat.get("supercategory","")}
    for split, data in all_coco_data.items():
        cnt = sum(1 for ann in data.get("annotations",[]) if ann["category_id"]==cid)
        row[f"count_{split}"] = cnt
    row["total"] = sum(row.get(f"count_{s}",0) for s in ["train","val","test"])
    cat_dist_rows.append(row)
    summary_data["categories"].append(cat)

for split, data in all_coco_data.items():
    imgs = data.get("images",[])
    anns = data.get("annotations",[])
    summary_data["splits"][split] = {
        "images": len(imgs),
        "annotations": len(anns),
        "images_without_annotations": len({img["id"] for img in imgs} - {ann["image_id"] for ann in anns}),
        "categories": len(data.get("categories",[])),
    }
    summary_data["total_images_coco"] += len(imgs)
    summary_data["total_annotations_coco"] += len(anns)

summary_data["image_info"] = all_image_info

summary_path = OUT / "dataset_summary.json"
with open(summary_path, "w", encoding="utf-8") as f:
    json.dump(summary_data, f, indent=2)
print(f"  dataset_summary.json → {summary_path}")

# --- class_distribution.csv ---
class_dist_path = OUT / "class_distribution.csv"
with open(class_dist_path, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["id","name","supercategory","count_train","count_val","count_test","total"])
    w.writeheader()
    w.writerows(cat_dist_rows)
print(f"  class_distribution.csv → {class_dist_path}")

# --- issues_list.csv ---
issues = []
for split, data in all_coco_data.items():
    imgs  = data.get("images",[])
    anns  = data.get("annotations",[])
    img_ids = {img["id"] for img in imgs}
    ann_img_ids = {ann["image_id"] for ann in anns}
    img_dims = {img["id"]: (img.get("width",0), img.get("height",0)) for img in imgs}

    imgs_no_ann = img_ids - ann_img_ids
    for iid in imgs_no_ann:
        img_obj = next((im for im in imgs if im["id"]==iid), {})
        issues.append({
            "split": split,
            "issue_type": "image_without_annotation",
            "severity": "CRITICAL",
            "image_id": iid,
            "file_name": img_obj.get("file_name",""),
            "detail": "Image has no annotations",
        })

    anns_no_img = ann_img_ids - img_ids
    for iid in anns_no_img:
        issues.append({
            "split": split,
            "issue_type": "annotation_without_image",
            "severity": "CRITICAL",
            "image_id": iid,
            "file_name": "",
            "detail": "Annotation references non-existent image",
        })

    # bbox issues
    for ann in anns:
        if "bbox" not in ann:
            issues.append({
                "split": split, "issue_type": "missing_bbox", "severity": "CRITICAL",
                "image_id": ann["image_id"], "file_name": "",
                "detail": f"Annotation {ann['id']} has no bbox field",
            })
            continue
        x,y,w,h = ann["bbox"]
        if w<=0 or h<=0:
            issues.append({
                "split": split, "issue_type": "invalid_bbox_dimensions", "severity": "CRITICAL",
                "image_id": ann["image_id"], "file_name": "",
                "detail": f"Ann {ann['id']} bbox w={w}, h={h} (non-positive)",
            })
        if ann["image_id"] in img_dims:
            iw, ih = img_dims[ann["image_id"]]
            if x<0 or y<0 or (x+w)>iw or (y+h)>ih:
                issues.append({
                    "split": split, "issue_type": "out_of_bounds_bbox", "severity": "HIGH",
                    "image_id": ann["image_id"], "file_name": "",
                    "detail": f"Ann {ann['id']} bbox ({x},{y},{w},{h}) exceeds image ({iw}x{ih})",
                })

# Cross-split leakage
if tv_overlap:
    for fn in tv_overlap:
        issues.append({"split":"train+val","issue_type":"data_leakage","severity":"CRITICAL","image_id":"","file_name":fn,"detail":"Same filename in both train and val"})
if tt_overlap:
    for fn in tt_overlap:
        issues.append({"split":"train+test","issue_type":"data_leakage","severity":"CRITICAL","image_id":"","file_name":fn,"detail":"Same filename in both train and test"})
if vt_overlap:
    for fn in vt_overlap:
        issues.append({"split":"val+test","issue_type":"data_leakage","severity":"CRITICAL","image_id":"","file_name":fn,"detail":"Same filename in both val and test"})

issues_path = OUT / "issues_list.csv"
with open(issues_path, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["split","issue_type","severity","image_id","file_name","detail"])
    w.writeheader()
    w.writerows(issues)

print(f"  issues_list.csv → {issues_path}  ({len(issues)} issues found)")

print()
print("="*70)
print("ANALYSIS COMPLETE")
print("="*70)
print(f"Output files in: {OUT}")
