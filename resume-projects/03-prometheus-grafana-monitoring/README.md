# 📊 Production Monitoring Stack — Prometheus + Grafana on GKE

> End-to-end observability stack deployed on Google Kubernetes Engine.
> Prometheus scrapes live metrics from a Flask application,
> Grafana visualizes them as real-time dashboards.

---

## 🎯 What This Project Demonstrates

| Skill | Implementation |
|-------|---------------|
| Observability | Prometheus metrics scraping every 15 seconds |
| Visualization | Grafana dashboards with live CPU + memory graphs |
| Kubernetes ConfigMap | Prometheus config stored and mounted as volume |
| Service Discovery | Prometheus scrapes via Kubernetes service name |
| Multi-service Deployment | 3 services running together on same GKE cluster |

---

## 🏗️ Architecture
```
Flask App (/metrics endpoint)
        ↓ scraped every 15 seconds
Prometheus (stores time-series data)
        ↓ queried by
Grafana (visualizes as dashboards)
        ↓
DevOps team sees live CPU + memory trends
        ↓
Alert fires if CPU > threshold
```

---

## 🛠️ Tech Stack

- **Metrics App:** Python Flask + prometheus_client
- **Monitoring:** Prometheus
- **Visualization:** Grafana
- **Orchestration:** Kubernetes (GKE)
- **Config Management:** Kubernetes ConfigMap

---

## 📁 Project Structure
```
03-prometheus-grafana-monitoring/
└── kubernetes/
    ├── prometheus-configmap.yaml    # scrape config — targets, interval, path
    ├── prometheus-deployment.yaml   # Prometheus pod + volume mount
    ├── prometheus-service.yaml      # LoadBalancer — external UI access
    ├── grafana-deployment.yaml      # Grafana pod with admin credentials
    └── grafana-service.yaml         # LoadBalancer — external UI access
```

---

## ⚡ Quick Start

### Prerequisites
- GKE cluster running (see Project 02)
- Flask metrics app deployed with `/metrics` endpoint

### Deploy Monitoring Stack
```bash
kubectl apply -f kubernetes/prometheus-configmap.yaml
kubectl apply -f kubernetes/prometheus-deployment.yaml
kubectl apply -f kubernetes/prometheus-service.yaml
kubectl apply -f kubernetes/grafana-deployment.yaml
kubectl apply -f kubernetes/grafana-service.yaml
```

### Get External IPs
```bash
kubectl get services
# Prometheus UI → EXTERNAL-IP of prometheus-service
# Grafana UI    → EXTERNAL-IP of grafana-service
```

### Configure Grafana

1. Open Grafana UI → Login (admin/admin123)
2. Connections → Data Sources → Add Prometheus
3. URL: `http://PROMETHEUS-EXTERNAL-IP`
4. Save & Test
5. Create dashboard → Add panel → Query: `cpu_percent`

---

## 🧠 Key Engineering Decisions

**1. ConfigMap for Prometheus Configuration**

Prometheus config stored as Kubernetes ConfigMap and mounted
as volume at `/etc/prometheus/prometheus.yml` — config changes
don't require rebuilding the container image.

**2. Service Name as Scrape Target**
```yaml
targets: ['flask-metrics-service:80']
```

Using Kubernetes service name instead of pod IP — survives
pod restarts and scaling. Service name stays constant even
when pod IPs change.

**3. Prometheus Exposition Format**

Flask app updated to use `prometheus_client` library —
returns metrics in Prometheus exposition format instead of JSON:
```
# HELP cpu_percent CPU usage percent
# TYPE cpu_percent gauge
cpu_percent 6.7
```

---

## 📊 Available Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `cpu_percent` | Gauge | Live CPU usage % |
| `memory_percent` | Gauge | Live memory usage % |
| `process_cpu_seconds_total` | Counter | Total CPU seconds |
| `python_gc_collections_total` | Counter | GC collections |

---

## 🔮 Future Improvements

- [ ] Add AlertManager for email/Slack notifications
- [ ] Configure alert rules for CPU > 80% threshold
- [ ] Add Node Exporter for host-level metrics
- [ ] Persistent volume for Prometheus data storage
- [ ] Pre-built Grafana dashboard as code (dashboard.json)

---

## 💡 Real World Context

This stack mirrors the industry standard observability pattern:
```
App exposes /metrics → Prometheus scrapes → Grafana visualizes → AlertManager notifies
```

Used by Netflix, Uber, Spotify, and most cloud-native companies
for production monitoring.

---

## 📸 Dashboard Preview

Live monitoring dashboard showing real-time CPU and memory metrics
from Flask app running on GKE — scraped by Prometheus every 15 seconds.

<img width="955" height="398" alt="image" src="https://github.com/user-attachments/assets/eeb90e83-cb23-4c4f-92b0-9864de2adecd" />


*Extends Project 02 — Flask Metrics App on GKE*
