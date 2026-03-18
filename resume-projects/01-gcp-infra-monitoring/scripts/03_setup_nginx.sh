#!/bin/bash
# ============================================================
# 03_setup_nginx.sh — Install & configure Nginx reverse proxy
# Run this locally; it SSHes into the proxy VM and configures it
# ============================================================
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# Get private IPs of the app servers
APP1_IP=$(gcloud compute instances describe "$APP_VM_1" \
  --zone="$ZONE" --project="$PROJECT_ID" \
  --format='get(networkInterfaces[0].networkIP)')

APP2_IP=$(gcloud compute instances describe "$APP_VM_2" \
  --zone="$ZONE" --project="$PROJECT_ID" \
  --format='get(networkInterfaces[0].networkIP)')

echo "==> App server IPs: $APP1_IP, $APP2_IP"
echo "==> Uploading Nginx config and applying on proxy VM..."

# Build nginx config with actual IPs injected
cat > /tmp/nginx_infra.conf <<EOF
# ── Upstream: app servers in private subnet ──────────────────
upstream app_backend {
    server ${APP1_IP}:8080;
    server ${APP2_IP}:8080;
}

server {
    listen 80;
    server_name _;

    # Access and error logs
    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    location / {
        proxy_pass         http://app_backend;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_connect_timeout 10s;
        proxy_read_timeout    30s;
    }

    # Health check endpoint (no backend needed)
    location /healthz {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# Copy config to the VM and restart Nginx
gcloud compute scp /tmp/nginx_infra.conf \
  "${PROXY_VM}:/tmp/nginx_infra.conf" \
  --zone="$ZONE" --project="$PROJECT_ID"

gcloud compute ssh "$PROXY_VM" --zone="$ZONE" --project="$PROJECT_ID" -- bash -s <<'REMOTE'
  set -euo pipefail
  echo "-- Installing Nginx if not present..."
  sudo apt-get update -qq && sudo apt-get install -y nginx

  echo "-- Applying reverse proxy config..."
  sudo cp /tmp/nginx_infra.conf /etc/nginx/sites-available/infra-proxy
  sudo ln -sf /etc/nginx/sites-available/infra-proxy /etc/nginx/sites-enabled/infra-proxy
  sudo rm -f /etc/nginx/sites-enabled/default

  echo "-- Testing config..."
  sudo nginx -t

  echo "-- Reloading Nginx..."
  sudo systemctl reload nginx
  sudo systemctl enable nginx

  echo "-- Nginx status:"
  sudo systemctl status nginx --no-pager
REMOTE

echo ""
PROXY_IP=$(gcloud compute instances describe "$PROXY_VM" \
  --zone="$ZONE" --project="$PROJECT_ID" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "✅ Nginx configured."
echo "   Proxy public IP : $PROXY_IP"
echo "   Test: curl http://$PROXY_IP/healthz"
echo ""
echo "   Next: bash scripts/04_setup_monitoring.sh"
