# Database user
# MongoDB Atlas Database Username
resource "random_string" "mongodb_user" {
  length  = 12
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# MongoDB Atlas Database Password
resource "random_password" "mongodb_pass" {
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true

  # MongoDB Atlas allows most special characters, but excluding problematic ones
  # that could cause issues in connection strings or shell commands
  override_special = "!@#$%^&*()_+-=[]{}|;:,.<>?"
}

resource "mongodbatlas_database_user" "projection_store_user" {
  username           = random_string.mongodb_user.result
  password           = random_password.mongodb_pass.result
  project_id         = var.atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "dbAdmin"
    database_name = "projections"
  }

  roles {
    role_name     = "readWrite"
    database_name = "projections"
  }

  scopes {
    name = mongodbatlas_cluster.projection_store.name
    type = "CLUSTER"
  }
}