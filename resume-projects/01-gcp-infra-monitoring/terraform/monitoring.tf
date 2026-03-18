# ── Notification Channel — Email ─────────────────────────────

resource "google_monitoring_notification_channel" "email_alert" {
  display_name = "Infra Alerts Email"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
}

# ── Alert Policy: CPU > 80% ───────────────────────────────────

resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Utilization (>80%)"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "CPU utilization above 80%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alert.id]

  documentation {
    content = "CPU > 80% for 5 minutes on a GCE instance. Check: top, ps aux, or Cloud Logging for the offending process."
  }
}

# ── Alert Policy: Disk > 90% ──────────────────────────────────

resource "google_monitoring_alert_policy" "disk_alert" {
  display_name = "High Disk Utilization (>90%)"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Disk used above 90%"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/disk/percent_used\""
      comparison      = "COMPARISON_GT"
      threshold_value = 90
      duration        = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alert.id]

  documentation {
    content = "Disk usage exceeded 90%. Archive logs to GCS bucket immediately to free space."
  }
}

# ── Uptime Check: Nginx /healthz ──────────────────────────────

resource "google_monitoring_uptime_check_config" "nginx_healthz" {
  display_name = "Nginx Proxy Health Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/healthz"
    port         = 80
    use_ssl      = false
    validate_ssl = false
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = google_compute_instance.nginx_proxy.network_interface[0].access_config[0].nat_ip
    }
  }
}
