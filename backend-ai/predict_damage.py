from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable

from ultralytics import YOLO


DEFAULT_MODEL = Path("runs/detect/train_m/weights/best.pt")
DEFAULT_SOURCE = Path("datasets/cardd_yolo/images/test/000012.jpg")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run the trained CarDD YOLO model on an image or folder and print a "
            "plain-language car damage summary."
        )
    )
    parser.add_argument(
        "source",
        nargs="?",
        default=str(DEFAULT_SOURCE),
        help="Image, folder, video, or camera source to inspect.",
    )
    parser.add_argument(
        "--model",
        default=str(DEFAULT_MODEL),
        help="Path to the trained YOLO weights.",
    )
    parser.add_argument(
        "--conf",
        type=float,
        default=0.25,
        help="Minimum confidence for detections.",
    )
    parser.add_argument(
        "--iou",
        type=float,
        default=0.7,
        help="IoU threshold used by non-max suppression.",
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=768,
        help="Image size for prediction. 768 matches the train_m run.",
    )
    parser.add_argument(
        "--project",
        default=None,
        help=(
            "Optional YOLO project folder. Leave empty to save under runs/detect; "
            "relative values are saved inside runs/detect."
        ),
    )
    parser.add_argument(
        "--name",
        default="predict_custom",
        help="Prediction run name under the project folder.",
    )
    parser.add_argument(
        "--hide",
        action="store_true",
        help="Do not save annotated images.",
    )
    parser.add_argument(
        "--save-txt",
        action="store_true",
        help="Also save YOLO-format prediction labels.",
    )
    parser.add_argument(
        "--save-conf",
        action="store_true",
        help="Include confidence values in saved YOLO labels.",
    )
    return parser.parse_args()


def validate_path(path_value: str, label: str) -> Path:
    path = Path(path_value)
    if not path.exists():
        raise FileNotFoundError(f"{label} was not found: {path}")
    return path


def class_summary(class_ids: Iterable[int], names: dict[int, str]) -> str:
    counts = Counter(class_ids)
    return ", ".join(f"{count} {names.get(class_id, str(class_id))}" for class_id, count in counts.items())


def print_result_summary(results, names: dict[int, str]) -> None:
    total_detections = 0
    total_by_class: Counter[int] = Counter()
    best_conf_by_class: defaultdict[int, float] = defaultdict(float)

    print("\nPrediction summary")
    print("==================")

    for result in results:
        boxes = result.boxes
        detections = 0 if boxes is None else len(boxes)
        total_detections += detections

        print(f"\nImage: {result.path}")

        if detections == 0:
            print("Status: no visible car damage detected")
            continue

        class_ids = [int(class_id) for class_id in boxes.cls.tolist()]
        confidences = [float(conf) for conf in boxes.conf.tolist()]

        for class_id, confidence in zip(class_ids, confidences):
            total_by_class[class_id] += 1
            best_conf_by_class[class_id] = max(best_conf_by_class[class_id], confidence)

        print("Status: possible accident / car damage detected")
        print(f"Detections: {detections} ({class_summary(class_ids, names)})")

        for class_id, confidence in zip(class_ids, confidences):
            class_name = names.get(class_id, str(class_id))
            print(f" - {class_name}: {confidence:.2%}")

    print("\nOverall")
    print("=======")

    if total_detections == 0:
        print("No damage was detected in the provided source.")
        return

    print(f"Damage detected: yes ({total_detections} total detection(s))")
    print(f"Classes: {class_summary(total_by_class.elements(), names)}")
    print("Best confidence by class:")
    for class_id, confidence in sorted(best_conf_by_class.items()):
        class_name = names.get(class_id, str(class_id))
        print(f" - {class_name}: {confidence:.2%}")


def main() -> None:
    args = parse_args()
    model_path = validate_path(args.model, "Model")
    source_path = validate_path(args.source, "Source")

    model = YOLO(str(model_path))
    results = model.predict(
        source=str(source_path),
        conf=args.conf,
        iou=args.iou,
        imgsz=args.imgsz,
        save=not args.hide,
        save_txt=args.save_txt,
        save_conf=args.save_conf,
        project=args.project,
        name=args.name,
        exist_ok=False,
    )

    names = {int(key): value for key, value in model.names.items()}
    print_result_summary(results, names)

    if not args.hide:
        save_dir = getattr(results[0], "save_dir", None) if results else None
        if save_dir is None and getattr(model, "predictor", None) is not None:
            save_dir = getattr(model.predictor, "save_dir", None)
        if save_dir is not None:
            print(f"\nAnnotated output saved to: {save_dir}")


if __name__ == "__main__":
    main()
