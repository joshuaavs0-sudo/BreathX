import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import pickle

# Load dataset
df = pd.read_csv('respi_master_dataset.csv')
X = df.drop(columns=['label']).values
y = df['label'].values

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train Classifier
ai_model = RandomForestClassifier(n_estimators=150, random_state=42)
ai_model.fit(X_train, y_train)

# Test accuracy
score = ai_model.score(X_test, y_test)
print(f"🌲 AI Model Training Complete. Validation Accuracy: {score * 100:.2f}%")

# Save model file
with open('respi_classifier.pkl', 'wb') as f:
    pickle.dump(ai_model, f)
print("💾 AI Engine locked and exported as 'respi_classifier.pkl'")
