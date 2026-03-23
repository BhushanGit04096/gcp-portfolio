from flask import Flask
from prometheus_client import Gauge, generate_latest, CONTENT_TYPE_LATEST
import psutil

app = Flask(__name__)

cpu_gauge = Gauge('cpu_percent', 'CPU usage percent')
memory_gauge = Gauge('memory_percent', 'Memory usage percent')

@app.route('/')
def home():
    return "Flask Metrics App is running!"

@app.route('/metrics')
def metrics():
    cpu_gauge.set(psutil.cpu_percent(interval=1))
    memory_gauge.set(psutil.virtual_memory().percent)
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
