#!/bin/bash
# ============================================================
# 02_deploy_infra.sh — VPC, subnets, firewall rules, VMs, bucket
# ============================================================
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# ── VPC ────────────────────────────────────────────────────
echo "==> Creating custom VPC: $VPC_NAME"
gcloud compute networks create "$VPC_NAME" \
  --subnet-mode=custom \
  --project="$PROJECT_ID" 2>/dev/null || echo "VPC already exists"

# ── Subnets ────────────────────────────────────────────────
echo "==> Creating public subnet: $PUBLIC_SUBNET ($PUBLIC_SUBNET_CIDR)"
gcloud compute networks subnets create "$PUBLIC_SUBNET" \
  --network="$VPC_NAME" \
  --region="$REGION" \
  --range="$PUBLIC_SUBNET_CIDR" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Public subnet already exists"

echo "==> Creating private subnet: $PRIVATE_SUBNET ($PRIVATE_SUBNET_CIDR)"
gcloud compute networks subnets create "$PRIVATE_SUBNET" \
  --network="$VPC_NAME" \
  --region="$REGION" \
  --range="$PRIVATE_SUBNET_CIDR" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Private subnet already exists"

# ── Firewall Rules ──────────────────────────────────────────
echo "==> Creating firewall rules (least-privilege)..."

# Allow HTTP/HTTPS from internet to public subnet (Nginx proxy)
gcloud compute firewall-rules create allow-http-https \
  --network="$VPC_NAME" \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:80,tcp:443 \
  --source-ranges="0.0.0.0/0" \
  --target-tags="nginx-proxy" \
  --project="$PROJECT_ID" 2>/dev/null || echo "HTTP/HTTPS rule exists"

# SSH: restricted to your IP only
gcloud compute firewall-rules create allow-ssh-restricted \
  --network="$VPC_NAME" \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges="$MY_IP" \
  --target-tags="allow-ssh" \
  --project="$PROJECT_ID" 2>/dev/null || echo "SSH rule exists"

# Internal traffic: public → private subnet
gcloud compute firewall-rules create allow-internal \
  --network="$VPC_NAME" \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:0-65535,udp:0-65535,icmp \
  --source-ranges="$PUBLIC_SUBNET_CIDR,$PRIVATE_SUBNET_CIDR" \
  --project="$PROJECT_ID" 2>/dev/null || echo "Internal rule exists"

# ── VMs ─────────────────────────────────────────────────────
echo "==> Creating Nginx proxy VM (public subnet)..."
gcloud compute instances create "$PROXY_VM" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --network="$VPC_NAME" \
  --subnet="$PUBLIC_SUBNET" \
  --image-family="$IMAGE_FAMILY" \
  --image-project="$IMAGE_PROJECT" \
  --tags="nginx-proxy,allow-ssh" \
  --service-account="${SA_PROXY}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --scopes=cloud-platform \
  --metadata=startup-script='#!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx' \
  --project="$PROJECT_ID" 2>/dev/null || echo "Proxy VM already exists"

echo "==> Creating app-server-1 (private subnet, no public IP)..."
gcloud compute instances create "$APP_VM_1" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --network="$VPC_NAME" \
  --subnet="$PRIVATE_SUBNET" \
  --no-address \
  --image-family="$IMAGE_FAMILY" \
  --image-project="$IMAGE_PROJECT" \
  --tags="app-server" \
  --service-account="${SA_APP}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --scopes=cloud-platform \
  --project="$PROJECT_ID" 2>/dev/null || echo "app-server-1 already exists"

echo "==> Creating app-server-2 (private subnet, no public IP)..."
gcloud compute instances create "$APP_VM_2" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --network="$VPC_NAME" \
  --subnet="$PRIVATE_SUBNET" \
  --no-address \
  --image-family="$IMAGE_FAMILY" \
  --image-project="$IMAGE_PROJECT" \
  --tags="app-server" \
  --service-account="${SA_APP}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --scopes=cloud-platform \
  --project="$PROJECT_ID" 2>/dev/null || echo "app-server-2 already exists"

# ── Cloud Storage Bucket ─────────────────────────────────────
echo "==> Creating Cloud Storage bucket: $BUCKET_NAME"
gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://${BUCKET_NAME}" 2>/dev/null || echo "Bucket already exists"

echo "==> Applying 30-day lifecycle policy for log archival..."
cat > /tmp/lifecycle.json <<EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {"age": 30}
    }
  ]
}
EOF
gsutil lifecycle set /tmp/lifecycle.json "gs://${BUCKET_NAME}"

echo ""
echo "✅ Infrastructure deployed."
echo "   VMs:"
gcloud compute instances list --project="$PROJECT_ID" --filter="name~(nginx-proxy|app-server)"
echo ""
echo "   Next: bash scripts/03_setup_nginx.sh"
