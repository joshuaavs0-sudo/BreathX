import requests
import numpy as np

# Let's generate one mock data stream right now to pretend we are blowing into a device
x = np.linspace(0, 3, 150)
mock_athlete_breath = (900 * (x * np.exp(-1.8 * x)) * 2.8).astype(int).tolist()

# Define payload simulating user setup profile configuration
payload = {
    "raw_stream": mock_athlete_breath,
    "persona": "athlete",
    "current_baseline_age": 42
}

# Hit our local AI API endpoint
URL = "http://127.0.0.1:8000/analyze_breath"
print("Sending simulated data payload to your backend AI model...")

response = requests.post(URL, json=payload)
print("\n--- RESPONSE RETURNED FROM SERVER TO MOBILE APP ---")
print(response.json())