# 🚀 Flask Metrics — Production-Grade GKE Deployment

> A real-world DevOps project demonstrating end-to-end infrastructure automation:
> containerized Python app → Terraform-provisioned GCP infrastructure → 
> Kubernetes orchestration → automated CI/CD pipeline.

---

## 🎯 What This Project Demonstrates

| Skill | Implementation |
|-------|---------------|
| Infrastructure as Code | Terraform provisions VPC, Subnet, Firewall, GKE |
| Containerization | Docker with optimized layer caching |
| Container Orchestration | Kubernetes with high availability (2 replicas) |
| CI/CD Automation | GitHub Actions — build, tag, push on every commit |
| Cloud Networking | Custom VPC, subnet, firewall rules from scratch |
| Security Best Practices | Least privilege IAM, secrets management, .gitignore |

---

## 🏗️ Architecture
```
Developer pushes code
        │
        ▼
┌─────────────────────┐
│   GitHub Actions    │  ← Triggered on push to main
│  CI/CD Pipeline     │
│  ✓ Build image      │
│  ✓ Tag with SHA     │
│  ✓ Push to Hub      │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│    Docker Hub       │  ← Versioned image registry
│ flask-metrics:sha   │
└────────┬────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│              GCP (Terraform)                │
│  ┌─────────────────────────────────────┐   │
│  │         Custom VPC Network          │   │
│  │  ┌────────────┐  ┌───────────────┐  │   │
│  │  │  Subnet    │  │ Firewall Rules│  │   │
│  │  │10.0.0.0/24 │  │ TCP 80,443,   │  │   │
│  │  └────────────┘  │ 5000          │  │   │
│  │                  └───────────────┘  │   │
│  │  ┌──────────────────────────────┐   │   │
│  │  │       GKE Cluster            │   │   │
│  │  │  ┌──────────┐ ┌──────────┐   │   │   │
│  │  │  │  Node 1  │ │  Node 2  │   │   │   │
│  │  │  │ ┌──────┐ │ │ ┌──────┐ │   │   │   │
│  │  │  │ │ Pod 1│ │ │ │ Pod 2│ │   │   │   │
│  │  │  │ └──────┘ │ │ └──────┘ │   │   │   │
│  │  │  └──────────┘ └──────────┘   │   │   │
│  │  │         LoadBalancer         │   │   │
│  │  │      Public IP: exposed      │   │   │
│  │  └──────────────────────────────┘   │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
         │
         ▼
   User hits /metrics
   Gets live CPU + Memory stats
```

---

## 🛠️ Tech Stack

- **Language:** Python 3.11
- **Framework:** Flask
- **Metrics:** psutil (CPU, memory monitoring)
- **Container:** Docker
- **IaC:** Terraform
- **Cloud:** GCP (GKE, VPC, Cloud Networking)
- **Orchestration:** Kubernetes
- **CI/CD:** GitHub Actions
- **Registry:** Docker Hub

---

## 📁 Project Structure
```
02-flask-metrics-gke-terraform/
├── app/
│   ├── app.py                 # Flask API — /metrics endpoint
│   ├── requirements.txt       # flask, psutil
│   └── Dockerfile             # Optimized multi-layer build
├── terraform/
│   ├── main.tf                # VPC, Subnet, Firewall, GKE, Node Pool
│   ├── variables.tf           # Parameterized inputs
│   ├── outputs.tf             # Cluster endpoint outputs
│   └── terraform.tfvars       # ← gitignored, never committed
├── k8s/
│   ├── deployment.yaml        # 2 replicas, rolling update strategy
│   └── service.yaml           # LoadBalancer — external IP exposure
└── .github/workflows/
    └── cicd.yaml              # Automated build + push pipeline
```

---

## ⚡ Quick Start

### 1. Provision Infrastructure
```bash
cd terraform
terraform init
terraform apply
```
Creates: VPC → Subnet → Firewall Rules → GKE Cluster → Node Pool

### 2. Connect to Cluster
```bash
gcloud container clusters get-credentials flask-metrics-cluster \
  --zone us-central1-a \
  --project YOUR_PROJECT_ID
```

### 3. Deploy Application
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 4. Get Public IP
```bash
kubectl get services
# Hit http://EXTERNAL-IP/metrics
```

---

## 🔄 CI/CD Pipeline

Every push to `main` automatically:
```
git push → GitHub Actions triggered
              ↓
         Checkout code
              ↓
         Login to Docker Hub (via secrets)
              ↓
         docker build -t flask-metrics:${{ github.sha }}
              ↓
         docker push → Docker Hub
              ↓
         New versioned image ready for deployment
```

**Secrets managed via GitHub Actions secrets — never hardcoded.**

---

## 🧠 Key Engineering Decisions

**1. Docker Layer Caching**
```dockerfile
COPY requirements.txt .        # Layer 1 — cached unless deps change
RUN pip install -r requirements.txt  # Layer 2 — only reruns when deps change
COPY . .                       # Layer 3 — rebuilds on code change only
```
Saves significant build time in CI — dependencies don't reinstall on every code change.

**2. High Availability with 2 Replicas**

Kubernetes spreads pods across nodes. If one node fails, the other continues serving traffic — zero downtime.

**3. Commit SHA Image Tagging**

Every Docker image is tagged with `github.sha` — the exact Git commit that produced it. Enables instant rollback:
```bash
kubectl set image deployment/flask-metrics \
  flask-metrics=bhushan0496/flask-metrics-app:PREVIOUS_SHA
```

**4. Terraform State Management**

Infrastructure defined as code — entire GCP environment reproducible with `terraform apply`. No manual clicking, no configuration drift.

**5. Least Privilege Security**
- `terraform.tfvars` in `.gitignore` — project IDs never in version control
- GKE nodes use scoped oauth with only required GCP API access
- Docker credentials stored as GitHub secrets — never in code

---

## 📊 API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/metrics` | GET | Live CPU + memory stats |

**Sample Response:**
```json
{
  "cpu_percent": 4.3,
  "memory_percent": 62.1,
  "memory_total_mb": 3924.69,
  "memory_used_mb": 2437.89
}
```

---

## 🔮 Future Improvements

- [ ] Add Prometheus scraping from `/metrics` endpoint
- [ ] Grafana dashboard for cluster-wide visibility  
- [ ] Horizontal Pod Autoscaler (HPA) based on CPU threshold
- [ ] GKE deploy step in CI/CD pipeline
- [ ] Terraform remote state with GCS backend
- [ ] Multi-environment support (dev/staging/prod)

---

## 💡 Real World Context

This project follows the same patterns used in production:
- `/metrics` endpoint mirrors **Prometheus exporter** pattern
- Terraform IaC mirrors **GitOps** infrastructure management  
- SHA-tagged images mirror **immutable deployment** practices
- GitHub Actions pipeline mirrors **trunk-based development** CI/CD

---

*Built to demonstrate production-grade DevOps practices on GCP*
