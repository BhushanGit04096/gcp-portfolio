#!/bin/bash
# ============================================================
# 05_snapshot_backup.sh — Take snapshots of all VMs
# ============================================================
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

take_snapshot() {
  local VM_NAME="$1"
  local SNAP_NAME="${VM_NAME}-snapshot-${TIMESTAMP}"

  echo "==> Taking snapshot of $VM_NAME → $SNAP_NAME"
  gcloud compute disks snapshot "$VM_NAME" \
    --snapshot-names="$SNAP_NAME" \
    --zone="$ZONE" \
    --project="$PROJECT_ID"
  echo "   ✅ Snapshot created: $SNAP_NAME"
}

take_snapshot "$PROXY_VM"
take_snapshot "$APP_VM_1"
take_snapshot "$APP_VM_2"

echo ""
echo "✅ All snapshots created."
gcloud compute snapshots list \
  --project="$PROJECT_ID" \
  --filter="name~'snapshot-${TIMESTAMP}'" \
  --format="table(name,diskSizeGb,status,creationTimestamp)"

echo ""
echo "   To restore: bash scripts/06_restore_snapshot.sh"
