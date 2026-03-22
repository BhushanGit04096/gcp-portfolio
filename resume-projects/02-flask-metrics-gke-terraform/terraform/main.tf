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

resource "google_compute_firewall" "Firewall" {
    name = "flask-metrics-allow-web"
    network = google_compute_network.vpc.id

    allow {
      protocol = "tcp"
      ports = [ "80" , "443" , "5000" ]
    }

    source_ranges = ["0.0.0.0/0"]
  
}

resource "google_container_cluster" "GKEcluster" {
    name = "flask-metrics-cluster"
    location = var.zone

    network = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    remove_default_node_pool = true
    initial_node_count = 1

    deletion_protection = false
  
}

resource "google_container_node_pool" "name" {
    name = "flask-metrics-node-pool"
    location = var.zone
    cluster = google_container_cluster.GKEcluster.id

    node_count = 2

    node_config {
      machine_type = "e2-medium"
      oauth_scopes = [ "https://www.googleapis.com/auth/cloud-platform" ]
    }
  
}