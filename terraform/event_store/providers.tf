terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.90.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.15.0"
    }
  }
}

# PostgreSQL provider configuration
provider "postgresql" {
  host            = module.event_store_database.cluster_endpoint
  port            = 5432
  database        = "postgres"
  username        = random_string.db_user.result
  password        = random_password.db_pass.result
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}