# ── Cloud Storage Bucket — Log Archival ──────────────────────

resource "google_storage_bucket" "infra_logs" {
  name          = "${var.project_id}-infra-logs"
  location      = var.region
  force_destroy = true   # Allows terraform destroy to remove non-empty bucket

  uniform_bucket_level_access = true

  # Delete objects after 30 days (log archival policy)
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  # Optional: move to Nearline after 7 days before deletion
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

output "log_bucket_name" {
  value = google_storage_bucket.infra_logs.name
}
