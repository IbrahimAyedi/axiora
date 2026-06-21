from __future__ import annotations

import base64
import mimetypes
import os
import sys
from collections import Counter, defaultdict
from pathlib import Path
from threading import Lock
from typing import Dict, List, Optional
from uuid import uuid4

from flask import Flask, jsonify, request, send_from_directory, url_for
from flask_cors import CORS
from PIL import Image, UnidentifiedImageError
from ultralytics import YOLO
from werkzeug.exceptions import BadRequest, HTTPException
from werkzeug.utils import secure_filename


BASE_DIR = Path(__file__).resolve().parent
ROOT_DIR = BASE_DIR.parent

# Ensure project root is on sys.path so cost_estimator is importable from api/
_root_str = str(ROOT_DIR)
if _root_str not in sys.path:
    sys.path.insert(0, _root_str)

from cost_estimator.estimator import estimate_repair_cost  # noqa: E402

DEFAULT_MODEL_PATH = ROOT_DIR / "runs" / "detect" / "train_m" / "weights" / "best.pt"
MODEL_PATH = Path(os.getenv("MODEL_PATH", str(DEFAULT_MODEL_PATH)))
if not MODEL_PATH.is_absolute():
    MODEL_PATH = ROOT_DIR / MODEL_PATH

STORAGE_DIR = Path(os.getenv("API_STORAGE_DIR", str(BASE_DIR / "storage")))
if not STORAGE_DIR.is_absolute():
    STORAGE_DIR = ROOT_DIR / STORAGE_DIR

UPLOAD_DIR = STORAGE_DIR / "uploads"
RESULTS_DIR = STORAGE_DIR / "results"

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
DEFAULT_CONF = float(os.getenv("YOLO_CONF", "0.25"))
DEFAULT_IOU = float(os.getenv("YOLO_IOU", "0.7"))
DEFAULT_IMGSZ = int(os.getenv("YOLO_IMGSZ", "768"))
MAX_UPLOAD_MB = int(os.getenv("MAX_UPLOAD_MB", "100"))

model_lock = Lock()
loaded_model: Optional[YOLO] = None


def create_app() -> Flask:
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = MAX_UPLOAD_MB * 1024 * 1024

    # Allow browser, Flutter Web, mobile clients, and local tools from any origin.
    CORS(app, resources={r"/*": {"origins": "*"}})

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    register_routes(app)
    register_error_handlers(app)
    return app


def register_routes(app: Flask) -> None:
    @app.get("/")
    def index():
        return jsonify(
            {
                "service": "car-damage-detection-api",
                "status": "running",
                "endpoints": {
                    "health": "/health",
                    "test_client": "/test",
                    "classes": "/api/classes",
                    "predict": "/api/predict",
                },
            }
        )

    @app.get("/test")
    def test_client():
        return send_from_directory(BASE_DIR, "test_client.html", as_attachment=False)

    @app.get("/health")
    def health():
        return jsonify(
            {
                "status": "ok",
                "model_path": str(MODEL_PATH),
                "model_exists": MODEL_PATH.exists(),
                "cors": "allow-all",
            }
        )

    @app.get("/api/classes")
    def classes():
        model = get_model()
        return jsonify({"classes": normalize_names(model.names)})

    @app.post("/api/predict")
    def predict():
        files = collect_uploaded_files()
        conf = parse_float("conf", DEFAULT_CONF)
        iou = parse_float("iou", DEFAULT_IOU)
        imgsz = parse_int("imgsz", DEFAULT_IMGSZ)
        include_base64 = parse_bool("include_base64", default=True)

        vehicle, region = parse_vehicle_info()

        request_id = uuid4().hex
        upload_dir = UPLOAD_DIR / request_id
        result_dir = RESULTS_DIR / request_id
        upload_dir.mkdir(parents=True, exist_ok=True)
        result_dir.mkdir(parents=True, exist_ok=True)

        saved_paths = save_uploaded_images(files, upload_dir)
        model = get_model()

        response_results = []
        names = normalize_names(model.names)

        with model_lock:
            for image_path in saved_paths:
                yolo_results = model.predict(
                    source=str(image_path),
                    conf=conf,
                    iou=iou,
                    imgsz=imgsz,
                    save=False,
                    verbose=False,
                )

                if not yolo_results:
                    raise RuntimeError(f"No prediction result was returned for {image_path.name}")

                result = yolo_results[0]
                annotated_name = f"{image_path.stem}_detected.jpg"
                annotated_path = result_dir / annotated_name
                result.save(filename=str(annotated_path))

                payload = build_prediction_payload(
                    result=result,
                    names=names,
                    request_id=request_id,
                    annotated_name=annotated_name,
                    annotated_path=annotated_path,
                    include_base64=include_base64,
                )

                image_w = int(result.orig_shape[1])
                image_h = int(result.orig_shape[0])
                normalized_dets = normalize_detections_for_cost_estimator(
                    payload["detections"], image_w, image_h
                )
                try:
                    payload["cost_estimation"] = estimate_repair_cost(
                        vehicle=vehicle,
                        detections=normalized_dets,
                        region=region,
                    )
                except Exception as exc:
                    payload["cost_estimation"] = {
                        "currency": "TND",
                        "vehicle": vehicle,
                        "region": region,
                        "estimations": [],
                        "warning": "Cost estimation unavailable.",
                        "error": str(exc),
                    }

                response_results.append(payload)

        total_detections = sum(item["detections_count"] for item in response_results)
        detected_images = sum(1 for item in response_results if item["damage_detected"])

        return jsonify(
            {
                "request_id": request_id,
                "images_count": len(response_results),
                "damage_detected": total_detections > 0,
                "detected_images_count": detected_images,
                "total_detections": total_detections,
                "model": str(MODEL_PATH),
                "conf": conf,
                "iou": iou,
                "imgsz": imgsz,
                "results": response_results,
            }
        )

    @app.get("/api/results/<request_id>/<path:filename>")
    def result_image(request_id: str, filename: str):
        safe_request_id = secure_filename(request_id)
        if not safe_request_id:
            raise BadRequest("Invalid request id.")
        return send_from_directory(RESULTS_DIR / safe_request_id, filename, as_attachment=False)


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(Exception)
    def handle_error(error):
        if isinstance(error, HTTPException):
            status_code = error.code or 500
            message = error.description
        else:
            status_code = 500
            message = str(error)

        return jsonify({"error": message, "status_code": status_code}), status_code


def parse_env_bool(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value in (None, ""):
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def get_model() -> YOLO:
    global loaded_model

    if loaded_model is None:
        with model_lock:
            if loaded_model is None:
                if not MODEL_PATH.exists():
                    raise RuntimeError(f"YOLO model was not found at: {MODEL_PATH}")
                loaded_model = YOLO(str(MODEL_PATH))

    return loaded_model


def collect_uploaded_files():
    files = []
    for field_name in ("images", "image", "files", "file"):
        files.extend(request.files.getlist(field_name))

    files = [file for file in files if file and file.filename]
    if not files:
        raise BadRequest("Upload at least one image using form-data field 'images'.")

    return files


def save_uploaded_images(files, upload_dir: Path) -> List[Path]:
    saved_paths = []

    for index, file in enumerate(files, start=1):
        original_name = secure_filename(file.filename or f"image_{index}.jpg")
        if not original_name:
            original_name = f"image_{index}.jpg"

        extension = Path(original_name).suffix.lower()
        if extension not in ALLOWED_EXTENSIONS:
            allowed = ", ".join(sorted(ALLOWED_EXTENSIONS))
            raise BadRequest(f"Unsupported file type '{extension}'. Allowed types: {allowed}")

        stem = Path(original_name).stem or f"image_{index}"
        image_path = upload_dir / f"{index:03d}_{stem}{extension}"
        file.save(image_path)
        validate_image(image_path)
        saved_paths.append(image_path)

    return saved_paths


def validate_image(image_path: Path) -> None:
    try:
        with Image.open(image_path) as image:
            image.verify()
    except (UnidentifiedImageError, OSError) as exc:
        image_path.unlink(missing_ok=True)
        raise BadRequest(f"Uploaded file is not a valid image: {image_path.name}") from exc


def build_prediction_payload(
    result,
    names: Dict[int, str],
    request_id: str,
    annotated_name: str,
    annotated_path: Path,
    include_base64: bool,
) -> dict:
    detections = extract_detections(result, names)
    class_counts = Counter(item["class_name"] for item in detections)
    best_confidence = defaultdict(float)
    for item in detections:
        best_confidence[item["class_name"]] = max(best_confidence[item["class_name"]], item["confidence"])

    annotated_url = url_for(
        "result_image",
        request_id=request_id,
        filename=annotated_name,
        _external=True,
    )

    payload = {
        "original_image": Path(result.path).name,
        "annotated_image": annotated_name,
        "annotated_image_url": annotated_url,
        "damage_detected": len(detections) > 0,
        "status": (
            "possible accident / car damage detected"
            if detections
            else "no visible car damage detected"
        ),
        "detections_count": len(detections),
        "classes_count": dict(class_counts),
        "best_confidence_by_class": dict(best_confidence),
        "detections": detections,
        "image_shape": {
            "height": int(result.orig_shape[0]),
            "width": int(result.orig_shape[1]),
        },
        "processing_ms": {
            key: round(float(value), 2)
            for key, value in getattr(result, "speed", {}).items()
        },
    }

    if include_base64:
        payload["annotated_image_base64"] = image_to_data_url(annotated_path)

    return payload


def extract_detections(result, names: Dict[int, str]) -> List[dict]:
    boxes = result.boxes
    if boxes is None or len(boxes) == 0:
        return []

    class_ids = boxes.cls.detach().cpu().tolist()
    confidences = boxes.conf.detach().cpu().tolist()
    coordinates = boxes.xyxy.detach().cpu().tolist()

    detections = []
    for class_id, confidence, xyxy in zip(class_ids, confidences, coordinates):
        x1, y1, x2, y2 = [round(float(value), 2) for value in xyxy]
        detections.append(
            {
                "class_id": int(class_id),
                "class_name": names.get(int(class_id), str(int(class_id))),
                "confidence": round(float(confidence), 4),
                "confidence_percent": round(float(confidence) * 100, 2),
                "box": {
                    "x1": x1,
                    "y1": y1,
                    "x2": x2,
                    "y2": y2,
                    "width": round(x2 - x1, 2),
                    "height": round(y2 - y1, 2),
                },
            }
        )

    return detections


def image_to_data_url(image_path: Path) -> str:
    mime_type = mimetypes.guess_type(image_path.name)[0] or "image/jpeg"
    encoded = base64.b64encode(image_path.read_bytes()).decode("ascii")
    return f"data:{mime_type};base64,{encoded}"


def parse_vehicle_info():
    """Return (vehicle_dict, region_str) from form fields or JSON body. All fields optional."""
    if request.is_json:
        data = request.get_json(silent=True) or {}
        make = data.get("make", "Any")
        model = data.get("model", "Any")
        year = data.get("year", "Any")
        region = data.get("region", "Tunis")
    else:
        make = request.form.get("make", "Any")
        model = request.form.get("model", "Any")
        year = request.form.get("year", "Any")
        region = request.form.get("region", "Tunis")

    def _clean(val, default):
        s = str(val).strip() if val is not None else ""
        return s if s else default

    vehicle = {
        "make": _clean(make, "Any"),
        "model": _clean(model, "Any"),
        "year": _clean(year, "Any"),
    }
    return vehicle, _clean(region, "Tunis")


def normalize_detections_for_cost_estimator(
    raw_detections: List[dict],
    image_width: int,
    image_height: int,
) -> List[dict]:
    """
    Convert API detection dicts to the format expected by cost_estimator.

    Computes bbox_area_ratio from the box field (xyxy). Never raises.
    """
    normalized = []
    image_area = image_width * image_height if image_width and image_height else 0
    for det in raw_detections:
        if not isinstance(det, dict):
            continue

        bbox_area_ratio = None
        box = det.get("box")
        if box and image_area > 0:
            try:
                bbox_w = float(box.get("width", 0))
                bbox_h = float(box.get("height", 0))
                if bbox_w > 0 and bbox_h > 0:
                    bbox_area_ratio = round((bbox_w * bbox_h) / image_area, 6)
            except (TypeError, ValueError, ZeroDivisionError):
                bbox_area_ratio = None

        normalized.append(
            {
                "class_name": det.get("class_name"),
                "confidence": det.get("confidence"),
                "bbox_area_ratio": bbox_area_ratio,
            }
        )
    return normalized


def normalize_names(names) -> Dict[int, str]:
    return {int(key): value for key, value in names.items()}


def parse_float(name: str, default: float) -> float:
    value = request.form.get(name, request.args.get(name))
    if value in (None, ""):
        return default

    try:
        return float(value)
    except ValueError as exc:
        raise BadRequest(f"'{name}' must be a number.") from exc


def parse_int(name: str, default: int) -> int:
    value = request.form.get(name, request.args.get(name))
    if value in (None, ""):
        return default

    try:
        return int(value)
    except ValueError as exc:
        raise BadRequest(f"'{name}' must be an integer.") from exc


def parse_bool(name: str, default: bool) -> bool:
    value = request.form.get(name, request.args.get(name))
    if value in (None, ""):
        return default

    return str(value).strip().lower() in {"1", "true", "yes", "on"}


app = create_app()


if __name__ == "__main__":
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "5000"))
    debug = parse_env_bool("API_DEBUG", default=False)
    app.run(host=host, port=port, debug=debug)
