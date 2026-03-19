#!/bin/bash
# ============================================================
# helpers.sh — Shared variables used by all scripts
# EDIT THESE VALUES before running any script
# ============================================================

export PROJECT_ID="playground-s-11-96307afe"       # e.g. my-infra-project-123
export REGION="us-central1"
export ZONE="us-central1-a"
export ALERT_EMAIL="Nagabhushancherry@gmail.com"     # For Cloud Monitoring alerts

# Network
export VPC_NAME="infra-vpc"
export PUBLIC_SUBNET="public-subnet"
export PRIVATE_SUBNET="private-subnet"
export PUBLIC_SUBNET_CIDR="10.0.1.0/24"
export PRIVATE_SUBNET_CIDR="10.0.2.0/24"

# VMs
export PROXY_VM="nginx-proxy"
export APP_VM_1="app-server-1"
export APP_VM_2="app-server-2"
export MACHINE_TYPE="e2-medium"
export IMAGE_FAMILY="debian-12"
export IMAGE_PROJECT="debian-cloud"

# Storage
export BUCKET_NAME="${PROJECT_ID}-infra-logs"

# Service Accounts
export SA_PROXY="sa-nginx-proxy"
export SA_APP="sa-app-server"

# Your IP for SSH access (run: curl ifconfig.me)
export MY_IP="0.0.0.0/0"    # Replace with your actual IP e.g. "203.0.113.5/32"
