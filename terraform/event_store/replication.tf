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

# Create the replication user using null_resource since provider lacks superuser privileges
resource "null_resource" "create_replication_user" {
  triggers = {
    username = random_string.replication_user.result
    password = random_password.replication_password.result
  }

  provisioner "local-exec" {
    command = <<-EOF
      docker run --rm postgres:15 psql "postgresql://${module.database.cluster_master_username}:${module.database.cluster_master_password}@${module.database.cluster_endpoint}:5432/postgres?sslmode=require" -c "
      DO \$\$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${random_string.replication_user.result}') THEN
          CREATE USER ${random_string.replication_user.result} REPLICATION LOGIN PASSWORD '${random_password.replication_password.result}';
        END IF;
      END \$\$;
      "
    EOF
  }

  depends_on = [module.database]
}

# Grant CONNECT privilege on database (as in Java code)
resource "postgresql_grant" "replication_database_connect" {
  database    = "postgres"
  role        = random_string.replication_user.result
  object_type = "database"
  privileges  = ["CONNECT"]
  
  depends_on = [
    null_resource.create_replication_user
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
    null_resource.create_replication_user,
    null_resource.create_event_store_schema
  ]
}


# Create the replication publication
resource "postgresql_publication" "replication_publication" {
  name   = "replication_publication"
  owner  = module.database.cluster_master_username
  tables = ["event_store"]
  
  depends_on = [
    null_resource.create_event_store_schema,
    null_resource.create_replication_user
  ]
}

# Create a replication slot for Ambar using null_resource
resource "null_resource" "create_replication_slot" {
  triggers = {
    publication_name = postgresql_publication.replication_publication.name
  }

  provisioner "local-exec" {
    command = <<-EOF
      docker run --rm postgres:15 psql "postgresql://${random_string.replication_user.result}:${random_password.replication_password.result}@${module.database.cluster_endpoint}:5432/postgres?sslmode=require" -c "
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
    null_resource.create_replication_user
  ]
}