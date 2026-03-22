# Flask Metrics App - v2
from flask import Flask, jsonify
import psutil

app = Flask(__name__)

@app.route('/')
def home():
    return "Flask Metrics App is running!version 2"

@app.route('/metrics')
def metrics():
    return jsonify({
        "cpu_percent": psutil.cpu_percent(interval=1),
        "memory_percent": psutil.virtual_memory().percent,
        "memory_used_mb": round(psutil.virtual_memory().used / 1024 / 1024, 2),
        "memory_total_mb": round(psutil.virtual_memory().total / 1024 / 1024, 2)
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)