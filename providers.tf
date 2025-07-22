terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = ">= 1.4.0"
    }
    ambar = {
      source  = "ambarltd/ambar"
      version = ">= 1.0.11"
    }
  }
}