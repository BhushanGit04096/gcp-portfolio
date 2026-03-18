#!/bin/bash
# ============================================================
# 06_restore_snapshot.sh — Restore nginx-proxy from its latest
# snapshot (simulates disaster recovery RTO test)
# ============================================================
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

VM_TO_RESTORE="${1:-$PROXY_VM}"   # Pass VM name as arg, defaults to nginx-proxy

echo "==> Finding latest snapshot for: $VM_TO_RESTORE"
LATEST_SNAP=$(gcloud compute snapshots list \
  --project="$PROJECT_ID" \
  --filter="name~'${VM_TO_RESTORE}-snapshot'" \
  --sort-by="~creationTimestamp" \
  --format="value(name)" \
  --limit=1)

if [[ -z "$LATEST_SNAP" ]]; then
  echo "❌ No snapshot found for $VM_TO_RESTORE. Run 05_snapshot_backup.sh first."
  exit 1
fi

echo "   Using snapshot: $LATEST_SNAP"
RESTORE_DISK="${VM_TO_RESTORE}-restored-disk"
RESTORE_VM="${VM_TO_RESTORE}-restored"

# Step 1: Create a new disk from snapshot
echo "==> Creating disk from snapshot..."
gcloud compute disks create "$RESTORE_DISK" \
  --source-snapshot="$LATEST_SNAP" \
  --zone="$ZONE" \
  --project="$PROJECT_ID"

# Step 2: Create a new VM from that disk
echo "==> Creating restored VM: $RESTORE_VM"
gcloud compute instances create "$RESTORE_VM" \
  --zone="$ZONE" \
  --machine-type="$MACHINE_TYPE" \
  --disk="name=${RESTORE_DISK},boot=yes,auto-delete=yes" \
  --network="$VPC_NAME" \
  --subnet="$PUBLIC_SUBNET" \
  --tags="nginx-proxy,allow-ssh" \
  --service-account="${SA_PROXY}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --scopes=cloud-platform \
  --project="$PROJECT_ID"

# Step 3: Verify
echo ""
RESTORE_IP=$(gcloud compute instances describe "$RESTORE_VM" \
  --zone="$ZONE" --project="$PROJECT_ID" \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "✅ VM restored successfully."
echo "   Restored VM : $RESTORE_VM"
echo "   External IP : $RESTORE_IP"
echo ""
echo "   Test: curl http://${RESTORE_IP}/healthz"
echo ""
echo "   RTO validated. When done testing, delete the restored VM:"
echo "   gcloud compute instances delete $RESTORE_VM --zone=$ZONE"
