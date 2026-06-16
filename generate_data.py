import numpy as np
import pandas as pd
import os

def generate_profile_breath(persona, quality):
    x = np.linspace(0, 3, 150) # 3 seconds, 50Hz sampling = 150 points
    
    if quality == "invalid":
        # Lazy, weak coughs or short cheats
        peak = np.random.uniform(80, 220)
        curve = peak * (x * np.exp(-4.0 * x))
    elif persona == "athlete":
        # Explosive peak, massive lung capacity volume trail
        peak = np.random.uniform(850, 1000)
        curve = peak * (x * np.exp(-1.8 * x)) * 2.8
    elif persona == "singer":
        # Moderate peak, but exceptionally long, stable plateau sustain
        peak = np.random.uniform(500, 650)
        curve = peak * (np.sin(x * 0.8) * np.exp(-0.3 * x)) * 1.8
    else: # Standard Smoker / Normal baseline
        # Lower peak, faster decay due to airway resistance
        peak = np.random.uniform(450, 600)
        curve = peak * (x * np.exp(-2.5 * x)) * 2.2

    # Add realistic sensor noise and floor boundaries
    curve += np.random.normal(0, 12, 150)
    curve = np.clip(curve, 0, 1023)
    return curve.astype(int)

# Compile the dataset
records = []
labels = [] # 1 = Valid effort, 0 = Bad/Fake effort

# Generate samples
for _ in range(100):
    records.append(generate_profile_breath("athlete", "valid"))
    labels.append(1)
for _ in range(100):
    records.append(generate_profile_breath("singer", "valid"))
    labels.append(1)
for _ in range(100):
    records.append(generate_profile_breath("smoker", "valid"))
    labels.append(1)
for _ in range(100):
    records.append(generate_profile_breath("any", "invalid"))
    labels.append(0)

# Save to CSV
df = pd.DataFrame(records)
df['label'] = labels
df.to_csv('respi_master_dataset.csv', index=False)
print("✅ Master Dataset created successfully: 'respi_master_dataset.csv'")