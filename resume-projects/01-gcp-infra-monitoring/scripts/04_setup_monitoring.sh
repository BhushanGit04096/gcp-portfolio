#!/bin/bash
# ============================================================
# 04_setup_monitoring.sh — Alert policies for CPU, Disk, and
# Uptime checks via Cloud Monitoring API (gcloud)
# ============================================================
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "==> Creating email notification channel for: $ALERT_EMAIL"
CHANNEL_ID=$(gcloud beta monitoring channels create \
  --display-name="Infra Alerts Email" \
  --type=email \
  --channel-labels="email_address=${ALERT_EMAIL}" \
  --project="$PROJECT_ID" \
  --format="value(name)" 2>/dev/null | awk -F/ '{print $NF}')
echo "   Notification channel ID: $CHANNEL_ID"
CHANNEL_FULL="projects/${PROJECT_ID}/notificationChannels/${CHANNEL_ID}"

# ── Alert: CPU > 80% ─────────────────────────────────────────
echo "==> Creating CPU alert policy (threshold: 80%)..."
cat > /tmp/alert_cpu.json <<EOF
{
  "displayName": "High CPU Utilization",
  "conditions": [
    {
      "displayName": "CPU > 80%",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 0.8,
        "duration": "300s",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_MEAN"
          }
        ]
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "1800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": ["${CHANNEL_FULL}"],
  "documentation": {
    "mimeType": "text/markdown",
    "content": "CPU utilization exceeded 80% for 5 minutes. Check for runaway processes: top, ps aux, or Cloud Logging."
  }
}
EOF
gcloud alpha monitoring policies create \
  --policy-from-file=/tmp/alert_cpu.json \
  --project="$PROJECT_ID"

# ── Alert: Disk > 90% ────────────────────────────────────────
echo "==> Creating Disk alert policy (threshold: 90%)..."
cat > /tmp/alert_disk.json <<EOF
{
  "displayName": "High Disk Utilization",
  "conditions": [
    {
      "displayName": "Disk used > 90%",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": 90,
        "duration": "60s",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_MEAN"
          }
        ]
      }
    }
  ],
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": ["${CHANNEL_FULL}"],
  "documentation": {
    "mimeType": "text/markdown",
    "content": "Disk utilization exceeded 90%. Immediate action required: check logs, archive old files to GCS bucket."
  }
}
EOF
gcloud alpha monitoring policies create \
  --policy-from-file=/tmp/alert_disk.json \
  --project="$PROJECT_ID"

# ── Uptime Check: Nginx /healthz ─────────────────────────────
PROXY_IP=$(gcloud compute instances describe "$PROXY_VM" \
  --zone="$ZONE" --project="$PROJECT_ID" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "==> Creating HTTP uptime check for http://${PROXY_IP}/healthz..."
gcloud monitoring uptime create "nginx-proxy-healthcheck" \
  --resource-type=uptime-url \
  --hostname="${PROXY_IP}" \
  --path="/healthz" \
  --port=80 \
  --check-interval=60 \
  --project="$PROJECT_ID" 2>/dev/null || echo "Uptime check already exists"

echo ""
echo "✅ Monitoring configured."
echo "   Go to: https://console.cloud.google.com/monitoring/alerting?project=$PROJECT_ID"
echo ""
echo "   Next: bash scripts/05_snapshot_backup.sh  (or test DR now)"
