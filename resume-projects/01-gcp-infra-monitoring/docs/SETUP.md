# Setup Prerequisites

## 1. Install gcloud CLI

```bash
# macOS (Homebrew)
brew install --cask google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

## 2. Install Terraform

```bash
# macOS
brew install terraform

# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## 3. Authenticate with GCP

```bash
gcloud auth login
gcloud auth application-default login   # Required for Terraform
```

## 4. Find your Project ID

```bash
gcloud projects list
```

## 5. Find your public IP (for SSH firewall rule)

```bash
curl ifconfig.me
# Use as: "203.0.113.5/32" in helpers.sh MY_IP variable
```

## 6. Create a terraform.tfvars file

```bash
cd terraform
cat > terraform.tfvars <<EOF
project_id  = "your-gcp-project-id"
region      = "us-central1"
zone        = "us-central1-a"
alert_email = "your-email@example.com"
my_ip       = "YOUR_PUBLIC_IP/32"
EOF
```

## 7. Enable billing

Make sure billing is enabled on your GCP project:
https://console.cloud.google.com/billing

---

## Cost Estimate (approx.)

| Resource | Type | Est. Cost/month |
|---|---|---|
| nginx-proxy VM | e2-medium | ~$25 |
| app-server-1 VM | e2-medium | ~$25 |
| app-server-2 VM | e2-medium | ~$25 |
| Cloud Storage | 5GB | <$1 |
| Cloud Monitoring | Basic | Free tier |
| **Total** | | **~$75/month** |

> **Tip:** Stop VMs when not in use to avoid charges:
> `gcloud compute instances stop nginx-proxy app-server-1 app-server-2 --zone=us-central1-a`
