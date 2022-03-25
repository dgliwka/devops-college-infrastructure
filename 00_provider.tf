terraform {
  required_version = "~> 1.1.0"

  required_providers {
    aws = "~> 3.74.0"
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}
