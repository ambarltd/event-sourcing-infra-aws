# Generate credentials for the replication user
resource "random_string" "replication_user" {
  length  = 12
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

# Create the replication user
resource "postgresql_role" "ambar_replication" {
  name     = random_string.replication_user.result
  login    = true
  password = random_password.replication_password.result
  
  # Required privileges for Ambar replication
  replication = true
  
  depends_on = [module.database]
}

# Grant CONNECT privilege on database (as in Java code)
resource "postgresql_grant" "replication_database_connect" {
  database    = "postgres"
  role        = postgresql_role.ambar_replication.name
  object_type = "database"
  privileges  = ["CONNECT"]
  
  depends_on = [
    postgresql_role.ambar_replication
  ]
}

# Grant SELECT privileges on the event store table
resource "postgresql_grant" "replication_event_store_select" {
  database    = "postgres"
  role        = postgresql_role.ambar_replication.name
  schema      = "public"
  object_type = "table"
  objects     = ["event_store"]
  privileges  = ["SELECT"]
  
  depends_on = [
    postgresql_role.ambar_replication,
    null_resource.create_event_store_schema
  ]
}


# Create the replication publication
resource "postgresql_publication" "replication_publication" {
  name   = "replication_publication"
  owner  = module.database.cluster_master_username
  tables = ["event_store"]
  
  # Publish all DML operations (default behavior)
  publish_insert = true
  publish_update = true
  publish_delete = true
  publish_truncate = true
  
  depends_on = [
    null_resource.create_event_store_schema,
    postgresql_role.ambar_replication
  ]
}

# Create a replication slot for Ambar using null_resource
resource "null_resource" "create_replication_slot" {
  triggers = {
    publication_name = postgresql_publication.replication_publication.name
  }

  provisioner "local-exec" {
    command = <<-EOF
      PGPASSWORD="${random_password.replication_password.result}" psql -h "${module.database.cluster_endpoint}" -p 5432 -U "${random_string.replication_user.result}" -d postgres -c "
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
    postgresql_role.ambar_replication
  ]
}