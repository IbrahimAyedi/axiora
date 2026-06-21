# Car Damage Detection API

Flask API for the trained YOLO car damage model.

## Run

From the project root:

```powershell
.\.venv\Scripts\python.exe -m pip install -r api\requirements.txt
.\.venv\Scripts\python.exe api\app.py
```

Default URL:

```text
http://127.0.0.1:5000
```

The API enables CORS for all origins, so it can be called from web apps, Flutter Web, Android, iOS, and local tools.

## Endpoints

### `GET /health`

Checks that the API is running and that the YOLO model file exists.

### `GET /api/classes`

Returns the model classes:

```text
dent, scratch, crack, glass_shatter, lamp_broken, tire_flat
```

### `POST /api/predict`

Upload one or many images using `multipart/form-data`.

Accepted file field names:

```text
images, image, files, file
```

Optional form fields:

```text
conf=0.25
iou=0.7
imgsz=768
include_base64=true
```

`include_base64=true` returns the detected image directly in JSON as a data URL. The response also includes `annotated_image_url`, which is usually better for web and Flutter image widgets.

## PowerShell Example

```powershell
curl.exe -X POST http://127.0.0.1:5000/api/predict `
  -F "images=@datasets\cardd_yolo\images\test\000012.jpg" `
  -F "conf=0.25"
```

Upload multiple images:

```powershell
curl.exe -X POST http://127.0.0.1:5000/api/predict `
  -F "images=@datasets\cardd_yolo\images\test\000012.jpg" `
  -F "images=@datasets\cardd_yolo\images\test\000015.jpg" `
  -F "include_base64=false"
```

## Response Shape

```json
{
  "request_id": "abc123",
  "images_count": 1,
  "damage_detected": true,
  "total_detections": 1,
  "results": [
    {
      "original_image": "001_000012.jpg",
      "annotated_image_url": "http://127.0.0.1:5000/api/results/abc123/001_000012_detected.jpg",
      "annotated_image_base64": "data:image/jpeg;base64,...",
      "damage_detected": true,
      "status": "possible accident / car damage detected",
      "detections_count": 1,
      "classes_count": {
        "tire_flat": 1
      },
      "detections": [
        {
          "class_name": "tire_flat",
          "confidence": 0.9478,
          "confidence_percent": 94.78,
          "box": {
            "x1": 100.0,
            "y1": 120.0,
            "x2": 230.0,
            "y2": 260.0
          }
        }
      ]
    }
  ]
}
```

## Flutter Notes

Use `MultipartRequest` and add one or more files with field name `images`.

For displaying the result:

- Use `Image.network(result["annotated_image_url"])` when the API is reachable from the device.
- Use `Image.memory(base64Decode(...))` if you keep `include_base64=true`.

On Android emulator, replace `127.0.0.1` with `10.0.2.2`. On a physical phone, use your computer LAN IP address.

