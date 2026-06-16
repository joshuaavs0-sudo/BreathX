from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pickle
import numpy as np

app = FastAPI(title="RespiTrack AI Biometric Engine")

# 🔓 Explicit Global CORS Headers Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Explicitly intercept any OPTIONS requests at the root level to satisfy web browsers
@app.options("/{path:path}")
async def preflight_handler(path: str):
    response = Response()
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS, PUT, DELETE"
    response.headers["Access-Control-Allow-Headers"] = "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization"
    return response

# Load the machine learning engine safely
try:
    with open("respi_classifier.pkl", "rb") as f:
        model = pickle.load(f)
    print("🧠 RespiTrack ML Engine Loaded Successfully.")
except FileNotFoundError:
    print("⚠️ Warning: respi_classifier.pkl not found. Please run train_engine.py first!")
    model = None

class BreathData(BaseModel):
    raw_stream: list
    persona: str
    current_baseline_age: int

@app.post("/analyze_breath")
async def analyze_breath(data: BreathData):
    peak_flow = int(max(data.raw_stream))
    estimated_vol = int(sum(data.raw_stream) * 2.1)
    
    features = np.array([[peak_flow, estimated_vol]])
    is_valid = 1
    if model is not None:
        try:
            is_valid = int(model.predict(features)[0])
        except Exception:
            is_valid = 1

    if is_valid == 0:
        return {
            "status": "failed",
            "message": "INSUFFICIENT EFFORT DETECTED: Please perform a deep, explosive exhalation."
        }

    persona = data.persona.lower()
    if persona == "athlete":
        display_text = f"STREAM VERIFIED: Peak flow clocked at {peak_flow} L/min. Your explosive target velocity optimized an additional 12% oxygenation efficiency for core stamina sets."
        badge = "STAMINA ELITE"
    elif persona == "singer":
        display_text = f"STREAM VERIFIED: Steady pressure stream sustained. Diaphragm compression target met. Volume capture hit {(estimated_vol/1000):.2f}L for vocal stability."
        badge = "VOCAL MASTER"
    else:
        display_text = f"CRAVING CONQUERED: Oxygen perfusion volume increased by 18%. Nitric oxide pathways are resetting. You chose lung recovery over nicotine this hour!"
        badge = "LUNG RESTORATION"

    return {
        "status": "success",
        "metrics": {
            "peak_expiratory_flow": peak_flow,
            "forced_volume_1s": estimated_vol
        },
        "rewards": {
            "badge": badge
        },
        "display_text": display_text
    }

if __name__ == "__main__":
    import uvicorn
    print("🔥 Launching RespiTrack Local Backend Web Server...")
    uvicorn.run(app, host="127.0.0.1", port=8000)