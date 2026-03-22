provider "google" {
    project = var.project_id
    region = var.region
  
}

resource "google_compute_network" "name" {
    name = "flask-metrics-vpc"
    auto_create_subnetworks = false
  
}