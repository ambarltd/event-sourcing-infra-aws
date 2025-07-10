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

# We deploy resources in AWS to a customer application account, so we configure the provider with an IAM user AK + SK
provider "aws" {
  region = var.region
  # https://developer.hashicorp.com/terraform/language/settings/backends/configuration#partial-configuration
  # https://discuss.hashicorp.com/t/error-invalid-aws-region-ap-southeast-4/49985/2
  skip_region_validation = true
  access_key = var.application_account_aws_access_key
  secret_key = var.application_account_aws_secret_key
}

provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

provider "ambar" {
  endpoint = var.ambar_regional_endpoint
  api_key  = var.ambar_api_key
}