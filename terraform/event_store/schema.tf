# PostgreSQL provider configuration
provider "postgresql" {
  host            = module.database.cluster_endpoint
  port            = 5432
  database        = "postgres"
  username        = module.database.cluster_master_username
  password        = module.database.cluster_master_password
  sslmode         = "require"
  connect_timeout = 15
}

# Create event store tables using SQL execution via functions
resource "postgresql_function" "create_event_store_schema" {
  name     = "create_event_store_schema"
  returns  = "void"
  language = "plpgsql"
  body = <<-EOF
    BEGIN
      -- Create the main event store table (matching Java schema exactly)
      IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'event_store' AND schemaname = 'public') THEN
        CREATE TABLE event_store (
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
        
        -- Create indexes exactly as in Java code
        CREATE UNIQUE INDEX event_store_idx_event_aggregate_id_version ON event_store(aggregate_id, aggregate_version);
        CREATE UNIQUE INDEX event_store_idx_event_id ON event_store(event_id);
        CREATE INDEX event_store_idx_event_causation_id ON event_store(causation_id);
        CREATE INDEX event_store_idx_event_correlation_id ON event_store(correlation_id);
        CREATE INDEX event_store_idx_occurred_on ON event_store(recorded_on);
        CREATE INDEX event_store_idx_event_name ON event_store(event_name);
      END IF;
      
    END;
  EOF

  depends_on = [module.database]
}

# Execute the schema creation function
resource "postgresql_function_call" "create_schema" {
  function_name = postgresql_function.create_event_store_schema.name
  depends_on    = [postgresql_function.create_event_store_schema]
}