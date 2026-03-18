# ── Service Accounts (from iam.tf) referenced here ──────────

# ── Nginx Proxy VM (Public Subnet) ───────────────────────────
resource "google_compute_instance" "nginx_proxy" {
  name         = "nginx-proxy"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["nginx-proxy", "allow-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    # Public IP
    access_config {}
  }

  service_account {
    email  = google_service_account.sa_proxy.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    # Simple health endpoint
    echo "OK" > /var/www/html/healthz
  SCRIPT

  depends_on = [google_service_account.sa_proxy]
}

# ── App Server 1 (Private Subnet) ────────────────────────────
resource "google_compute_instance" "app_server_1" {
  name         = "app-server-1"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["app-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
    # No access_config = no public IP
  }

  service_account {
    email  = google_service_account.sa_app.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update -y
    # Install a simple app server (Python HTTP for demo)
    apt-get install -y python3
    mkdir -p /opt/app
    echo "Hello from app-server-1" > /opt/app/index.html
    cd /opt/app && python3 -m http.server 8080 &
  SCRIPT

  depends_on = [google_service_account.sa_app]
}

# ── App Server 2 (Private Subnet) ────────────────────────────
resource "google_compute_instance" "app_server_2" {
  name         = "app-server-2"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["app-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private.id
  }

  service_account {
    email  = google_service_account.sa_app.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3
    mkdir -p /opt/app
    echo "Hello from app-server-2" > /opt/app/index.html
    cd /opt/app && python3 -m http.server 8080 &
  SCRIPT

  depends_on = [google_service_account.sa_app]
}

# ── Outputs ──────────────────────────────────────────────────
output "nginx_proxy_public_ip" {
  value       = google_compute_instance.nginx_proxy.network_interface[0].access_config[0].nat_ip
  description = "Public IP of the Nginx reverse proxy"
}

output "app_server_1_private_ip" {
  value = google_compute_instance.app_server_1.network_interface[0].network_ip
}

output "app_server_2_private_ip" {
  value = google_compute_instance.app_server_2.network_interface[0].network_ip
}
