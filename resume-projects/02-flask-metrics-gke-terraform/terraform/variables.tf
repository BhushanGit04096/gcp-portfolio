variable "project_id" { 
    description = "GCP project ID"
    type = string
  
}

variable "region" {
    description = "GCP Region"
    type = string
    default = "us-central1"
  
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}