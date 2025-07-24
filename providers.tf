terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.90.0"
      configuration_aliases = [
        aws.main,
        aws.alt_region
      ]
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

provider "aws" {
  alias  = "main"
  region = var.region
}

provider "aws" {
  alias  = "alt_region"
  region = var.region == "ap-southeast-5" ? "eu-west-1" : var.region
}