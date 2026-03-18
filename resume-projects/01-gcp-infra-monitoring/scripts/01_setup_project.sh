#!/bin/bash
# ============================================================
# 01_setup_project.sh — Enable APIs and set active project
# ============================================================
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "==> Setting active project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

echo "==> Enabling required GCP APIs..."
gcloud services enable \
  compute.googleapis.com \
  storage.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="$PROJECT_ID"

echo "==> Creating service accounts..."

# Nginx proxy service account
gcloud iam service-accounts create "$SA_PROXY" \
  --display-name="Nginx Proxy VM SA" \
  --project="$PROJECT_ID" 2>/dev/null || echo "SA $SA_PROXY already exists"

# App server service account
gcloud iam service-accounts create "$SA_APP" \
  --display-name="App Server VM SA" \
  --project="$PROJECT_ID" 2>/dev/null || echo "SA $SA_APP already exists"

echo "==> Binding IAM roles..."

# Proxy VM: logs writer + monitoring writer only
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_PROXY}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_PROXY}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

# App VMs: logs + monitoring writer + storage object creator (for log archival)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_APP}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_APP}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_APP}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectCreator"

echo ""
echo "✅ Project setup complete."
echo "   Next: bash scripts/02_deploy_infra.sh"
