# GCP Infrastructure Deployment & Monitoring Project

A production-style, multi-tier VM architecture on GCP with custom VPC networking, IAM, Nginx reverse proxy, Cloud Storage, and full Cloud Monitoring dashboards — built from scratch using Terraform and gcloud CLI.

---

## Architecture Overview

```
Internet
    │
    ▼
[Firewall: allow HTTP/HTTPS]
    │
    ▼
[Public Subnet]  ──────────────────────────────────
│  nginx-proxy VM (Compute Engine)                 │
│  - Reverse proxy to private app VMs              │
│  - Nginx installed, HTTP port 80 exposed         │
└──────────────────────────────────────────────────┘
    │  Internal traffic only
    ▼
[Private Subnet]  ─────────────────────────────────
│  app-server-1 VM   |   app-server-2 VM           │
│  - No public IP    |   - No public IP            │
│  - App workloads   |   - App workloads           │
└──────────────────────────────────────────────────┘
    │
    ▼
[Cloud Storage Bucket]  ←  Log archival + static assets
    │
    ▼
[Cloud Monitoring]  ←  CPU / Memory / Disk alerts → Email
```

---

## Project Structure

```
gcp-infra-monitoring/
├── terraform/
│   ├── main.tf              # VPC, subnets, firewall rules
│   ├── compute.tf           # VM instances
│   ├── storage.tf           # Cloud Storage bucket
│   ├── iam.tf               # Service accounts & IAM roles
│   ├── monitoring.tf        # Alert policies & notification channels
│   └── variables.tf         # All configurable inputs
├── scripts/
│   ├── 01_setup_project.sh  # Initial GCP project setup
│   ├── 02_deploy_infra.sh   # Deploy via gcloud CLI (no Terraform)
│   ├── 03_setup_nginx.sh    # Install & configure Nginx on proxy VM
│   ├── 04_setup_monitoring.sh # Create dashboards & alert policies
│   ├── 05_snapshot_backup.sh  # Take VM snapshots
│   ├── 06_restore_snapshot.sh # Restore VM from snapshot (DR test)
│   └── helpers.sh           # Shared variables used by all scripts
├── nginx/
│   └── nginx.conf           # Nginx reverse proxy config
├── monitoring/
│   └── dashboard.json       # Cloud Monitoring dashboard definition
├── docs/
│   └── SETUP.md             # Detailed setup prerequisites
└── README.md
```

---

## Prerequisites

1. A GCP account with billing enabled
2. `gcloud` CLI installed → https://cloud.google.com/sdk/docs/install
3. `terraform` installed (v1.5+) → https://developer.hashicorp.com/terraform/install
4. Authenticate: `gcloud auth login && gcloud auth application-default login`

---

## Quick Start — Terraform (Recommended)

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/gcp-infra-monitoring.git
cd gcp-infra-monitoring

# 2. Set your variables
cp terraform/variables.tf terraform/terraform.tfvars   # then edit values

# 3. Initialise and deploy
cd terraform
terraform init
terraform plan
terraform apply

# 4. SSH into the Nginx proxy VM and run the Nginx setup
gcloud compute ssh nginx-proxy --zone=us-central1-a
# (inside the VM)
bash /tmp/setup_nginx.sh
```

---

## Quick Start — Shell Scripts (gcloud CLI only)

```bash
# Step 1: Configure your project settings
nano scripts/helpers.sh        # Set PROJECT_ID, REGION, ZONE, EMAIL

# Step 2: Run each script in order
bash scripts/01_setup_project.sh
bash scripts/02_deploy_infra.sh
bash scripts/03_setup_nginx.sh
bash scripts/04_setup_monitoring.sh

# Step 3: Test disaster recovery
bash scripts/05_snapshot_backup.sh
bash scripts/06_restore_snapshot.sh
```

---

## What Each Component Does

| Component | Purpose |
|---|---|
| Custom VPC | Isolated network; no default VPC used |
| Public Subnet | Hosts the Nginx proxy VM with external IP |
| Private Subnet | Hosts app VMs with internal IPs only |
| Firewall Rules | Least-privilege — HTTP/HTTPS public; SSH restricted to your IP |
| IAM Service Accounts | Per-VM identities with minimal GCP permissions |
| Cloud Storage | Log archival with 30-day lifecycle policy |
| Cloud Monitoring | CPU > 80%, Memory > 85%, Disk > 90% → email alert |
| VM Snapshots | Daily snapshots; restore tested to validate RTO |

---

## Disaster Recovery Test

```bash
# Take snapshot of nginx-proxy
bash scripts/05_snapshot_backup.sh

# Delete the VM (simulates failure)
gcloud compute instances delete nginx-proxy --zone=us-central1-a

# Restore from snapshot
bash scripts/06_restore_snapshot.sh

# Verify it's back up
gcloud compute instances list
```

---

## Clean Up (avoid GCP charges)

```bash
cd terraform
terraform destroy
```
Or manually:
```bash
bash scripts/cleanup.sh
```

---

## Skills Demonstrated

- GCP Compute Engine, VPC, IAM, Cloud Storage, Cloud Monitoring
- Terraform IaC for repeatable infrastructure provisioning
- Nginx reverse proxy configuration on Linux
- Least-privilege IAM with service accounts
- Alerting and observability with Cloud Monitoring
- Disaster recovery via VM snapshots
