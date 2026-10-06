import io
import numpy as np
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from paddleocr import PaddleOCR

app = FastAPI(title="PaddleOCR Service")

# Initialize PaddleOCR (models download automatically on first run)
# Change lang='en' to 'ch', 'es', 'fr', etc. as needed
ocr = PaddleOCR(use_angle_cls=True, lang="en")

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.post("/ocr")
async def extract_text(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image.")

    try:
        # Read image into memory and convert to OpenCV-compatible numpy array
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        image_np = np.array(image)

        # Run OCR
        result = ocr.ocr(image_np, cls=True)

        parsed_results = []
        if result and result[0]:
            for line in result[0]:
                bbox, (text, confidence) = line
                parsed_results.append({
                    "text": text,
                    "confidence": float(confidence),
                    "bbox": bbox
                })

        return {
            "success": True,
            "count": len(parsed_results),
            "data": parsed_results
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))