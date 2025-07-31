# Generate credentials for a replication user for ambar
resource "random_string" "replication_user" {
  length  = 10
  special = false
  upper   = true
  lower   = true
  numeric = false
}

resource "random_password" "replication_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
  
  # Exclude characters that can cause issues in PostgreSQL or connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a regular user first using PostgreSQL provider
resource "postgresql_role" "ambar_replication" {
  name     = random_string.replication_user.result
  login    = true
  password = random_password.replication_password.result
  
  depends_on = [module.database]
}

# Grant replication privileges using AWS RDS API
resource "null_resource" "grant_replication_privileges" {
  triggers = {
    username = random_string.replication_user.result
  }

  provisioner "local-exec" {
    command = <<-EOF
      aws rds modify-db-cluster \
        --db-cluster-identifier ${module.database.cluster_id} \
        --master-user-password ${module.database.cluster_master_password} \
        --apply-immediately \
        --region ${var.region} || echo "Failed to modify cluster, user may already have privileges"
      
      # Grant rds_replication role to our user
      psql "postgresql://${module.database.cluster_master_username}:${module.database.cluster_master_password}@${module.database.cluster_endpoint}:5432/postgres?sslmode=require" -c "
      DO \$\$
      BEGIN
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${random_string.replication_user.result}') THEN
          GRANT rds_replication TO ${random_string.replication_user.result};
        END IF;
      EXCEPTION WHEN OTHERS THEN
        NULL; -- Ignore errors if role doesn't exist or grant fails
      END \$\$;
      "
    EOF
  }

  depends_on = [postgresql_role.ambar_replication]
}

# Grant CONNECT privilege on database (as in Java code)
resource "postgresql_grant" "replication_database_connect" {
  database    = "postgres"
  role        = random_string.replication_user.result
  object_type = "database"
  privileges  = ["CONNECT"]
  
  depends_on = [
    null_resource.grant_replication_privileges
  ]
}

# Grant SELECT privileges on the event store table
resource "postgresql_grant" "replication_event_store_select" {
  database    = "postgres"
  role        = random_string.replication_user.result
  schema      = "public"
  object_type = "table"
  objects     = ["event_store"]
  privileges  = ["SELECT"]
  
  depends_on = [
    null_resource.grant_replication_privileges,
    null_resource.create_event_store_schema
  ]
}


# Create the replication publication
resource "postgresql_publication" "replication_publication" {
  name   = "ambar_publication"
  tables = ["event_store"]
  
  depends_on = [
    null_resource.create_event_store_schema,
    null_resource.grant_replication_privileges
  ]
}

# Create a replication slot for Ambar using null_resource
resource "null_resource" "create_replication_slot" {
  triggers = {
    publication_name = postgresql_publication.replication_publication.name
  }

  provisioner "local-exec" {
    command = <<-EOF
      psql "postgresql://${random_string.replication_user.result}:${random_password.replication_password.result}@${module.database.cluster_endpoint}:5432/postgres?sslmode=require" -c "
      -- Create logical replication slot if it doesn't exist
      SELECT CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'ambar_event_store_slot') 
        THEN pg_create_logical_replication_slot('ambar_event_store_slot', 'pgoutput')
        ELSE NULL 
      END;
      "
    EOF
  }

  depends_on = [
    postgresql_publication.replication_publication,
    null_resource.grant_replication_privileges
  ]
}