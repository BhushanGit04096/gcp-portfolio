provider "google" {
    project = var.project_id
    region = var.region
  
}

resource "google_compute_network" "vpc" {
    name = "flask-metrics-vpc"
    auto_create_subnetworks = false
  
}

resource "google_compute_subnetwork" "subnet" {
    name = "flask-metrics-subnet"
    ip_cidr_range = "10.0.0.0/24"
    region = var.region
    network = google_compute_network.vpc.id
  
}

resource "google_compute_firewall" "name" {
    name = "flask-metrics-allow-web"
    network = google_compute_network.vpc.id

    allow {
      protocol = "tcp"
      ports = [ "80" , "443" , "5000" ]
    }

    source_ranges = "0.0.0.0/0"
  
}