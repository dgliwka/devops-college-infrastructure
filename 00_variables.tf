locals {
  default_tags = {
    Project     = var.project
    Environment = var.environment
    Terraform   = "true"
  }
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "dns_zone" {
  type = string
}

variable "dns_delegation_set" {
  type = string
}
