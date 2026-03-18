variable "project_id" {
  description = "Your GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "alert_email" {
  description = "Email address to receive Cloud Monitoring alerts"
  type        = string
}

variable "my_ip" {
  description = "Your public IP for SSH firewall rule (e.g. 203.0.113.5/32). Use 0.0.0.0/0 to allow all (not recommended)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "machine_type" {
  description = "Compute Engine machine type for all VMs"
  type        = string
  default     = "e2-medium"
}
