terraform {
  cloud {
    organization = "Timekiller"

    workspaces {
      name = "TechTask"
    }
  }

  #set minimum terraform version 
  required_version = ">=1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
  }
}
