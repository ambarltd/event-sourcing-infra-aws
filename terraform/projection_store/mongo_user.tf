# Database user
# MongoDB Atlas Database Username
resource "random_string" "mongodb_username" {
  length  = 14
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# MongoDB Atlas Database Password
resource "random_password" "mongodb_password" {
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
  username           = random_string.mongodb_username.result
  password           = random_password.mongodb_password.result
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
    name = var.mongodb_free_tier ? mongodbatlas_cluster.free_projection_store[0].name : mongodbatlas_cluster.projection_store[0].name
    type = "CLUSTER"
  }
}