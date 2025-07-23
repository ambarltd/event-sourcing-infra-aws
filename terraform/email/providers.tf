terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.ses]
    }
  }
}

# Provider for SES operations - uses eu-west-1 when current region is ap-southeast-5
provider "aws" {
  alias  = "ses"
  region = local.ses_region
}