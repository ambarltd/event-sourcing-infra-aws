# PostgreSQL provider configuration
provider "postgresql" {
  host            = module.database.cluster_endpoint
  port            = 5432
  database        = "postgres"
  username        = module.database.cluster_master_username
  password        = module.database.cluster_master_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

# Create event store tables using null_resource with local-exec
resource "null_resource" "create_event_store_schema" {
  triggers = {
    database_endpoint = module.database.cluster_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOF
      psql "postgresql://${module.database.cluster_master_username}:${module.database.cluster_master_password}@${module.database.cluster_endpoint}:5432/postgres?sslmode=require" -c "
      CREATE TABLE IF NOT EXISTS event_store (
        id BIGSERIAL NOT NULL,
        event_id TEXT NOT NULL UNIQUE,
        aggregate_id TEXT NOT NULL,
        aggregate_version BIGINT NOT NULL,
        causation_id TEXT NOT NULL,
        correlation_id TEXT NOT NULL,
        recorded_on TEXT NOT NULL,
        event_name TEXT NOT NULL,
        json_payload TEXT NOT NULL,
        json_metadata TEXT NOT NULL,
        PRIMARY KEY (id)
      );

      CREATE UNIQUE INDEX IF NOT EXISTS event_store_idx_event_aggregate_id_version ON event_store(aggregate_id, aggregate_version);
      CREATE UNIQUE INDEX IF NOT EXISTS event_store_idx_event_id ON event_store(event_id);
      CREATE INDEX IF NOT EXISTS event_store_idx_event_causation_id ON event_store(causation_id);
      CREATE INDEX IF NOT EXISTS event_store_idx_event_correlation_id ON event_store(correlation_id);
      CREATE INDEX IF NOT EXISTS event_store_idx_occurred_on ON event_store(recorded_on);
      CREATE INDEX IF NOT EXISTS event_store_idx_event_name ON event_store(event_name);
      "
    EOF
  }

  depends_on = [module.database]
}