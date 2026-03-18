# ── Service Accounts ─────────────────────────────────────────

resource "google_service_account" "sa_proxy" {
  account_id   = "sa-nginx-proxy"
  display_name = "Nginx Proxy VM Service Account"
}

resource "google_service_account" "sa_app" {
  account_id   = "sa-app-server"
  display_name = "App Server VM Service Account"
}

# ── IAM Bindings — Least Privilege ───────────────────────────

# Proxy: write logs + metrics only
resource "google_project_iam_member" "proxy_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.sa_proxy.email}"
}

resource "google_project_iam_member" "proxy_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sa_proxy.email}"
}

# App servers: write logs + metrics + push objects to GCS bucket
resource "google_project_iam_member" "app_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.sa_app.email}"
}

resource "google_project_iam_member" "app_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sa_app.email}"
}

resource "google_project_iam_member" "app_storage_writer" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.sa_app.email}"
}
