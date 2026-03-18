terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ── VPC ──────────────────────────────────────────────────────
resource "google_compute_network" "infra_vpc" {
  name                    = "infra-vpc"
  auto_create_subnetworks = false
}

# ── Subnets ──────────────────────────────────────────────────
resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.infra_vpc.id
}

resource "google_compute_subnetwork" "private" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.infra_vpc.id
}

# ── Firewall Rules ────────────────────────────────────────────
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.infra_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nginx-proxy"]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-restricted"
  network = google_compute_network.infra_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.my_ip]
  target_tags   = ["allow-ssh"]
  direction     = "INGRESS"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.infra_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.1.0/24", "10.0.2.0/24"]
  direction     = "INGRESS"
}
