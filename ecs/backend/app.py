# REPLACE THIS FILE WITH YOUR REAL app.py
from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/")
def index():
    return jsonify({"status": "ECS backend placeholder"})

@app.get("/health")
def health():
    return jsonify({"status": "healthy"})

@app.get("/metrics")
def metrics():
    return "# ECS backend placeholder metrics\n"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
