# Create event store tables using null_resource with local-exec
resource "null_resource" "create_event_store_schema" {
  triggers = {
    database_endpoint = module.event_store_database.cluster_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOF
      psql "postgresql://${module.event_store_database.cluster_master_username}:${module.event_store_database.cluster_master_password}@${module.event_store_database.cluster_endpoint}:5432/postgres?sslmode=require" -c "
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

      CREATE TABLE IF NOT EXISTS event_store_idempotent_reaction (
          event_id TEXT NOT NULL,
          reaction_name TEXT NOT NULL,
          PRIMARY KEY (event_id, reaction_name)
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

  depends_on = [module.event_store_database]
}