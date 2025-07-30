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

# Create the main event store table
resource "postgresql_table" "event_store" {
  name = "event_store"
  
  columns = [
    {
      name     = "id"
      type     = "BIGSERIAL"
      nullable = false
      primary_key = true
    },
    {
      name     = "event_id"
      type     = "text"
      nullable = false
    },
    {
      name     = "event_name"
      type     = "text"
      nullable = false
    },
    {
      name     = "aggregate_id"
      type     = "text"
      nullable = false
    },
    {
      name     = "aggregate_version"
      type     = "INTEGER"
      nullable = false
    },
    {
      name     = "json_payload"
      type     = "JSONB"
      nullable = false
    },
    {
      name     = "json_metadata"
      type     = "JSONB"
      nullable = true
    },
    {
      name     = "recorded_on"
      type     = "TIMESTAMP WITH TIME ZONE"
      nullable = false
      default  = "CURRENT_TIMESTAMP"
    },
    {
      name     = "causation_id"
      type     = "UUID"
      nullable = true
    },
    {
      name     = "correlation_id"
      type     = "UUID"
      nullable = false
    }
  ]

  depends_on = [module.database]
}

# Create the idempotent reactions table
resource "postgresql_table" "event_store_idempotent_reaction" {
  name = "event_store_idempotent_reaction"
  
  columns = [
    {
      name        = "id"
      type        = "BIGSERIAL"
      nullable    = false
      primary_key = true
    },
    {
      name     = "reaction_id"
      type     = "UUID"
      nullable = false
    },
    {
      name     = "aggregate_id"
      type     = "UUID"
      nullable = false
    },
    {
      name     = "aggregate_version"
      type     = "INTEGER"
      nullable = false
    },
    {
      name     = "processed_on"
      type     = "TIMESTAMP WITH TIME ZONE"
      nullable = false
      default  = "CURRENT_TIMESTAMP"
    }
  ]

  depends_on = [module.database]
}

# Create indexes for better performance
resource "postgresql_function" "create_event_store_indexes" {
  name = "create_event_store_indexes"
  returns = "void"
  language = "plpgsql"
  body = <<-EOF
    BEGIN
      -- Index on aggregate_id for faster lookups
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'event_store' AND indexname = 'idx_event_store_aggregate_id') THEN
        CREATE INDEX idx_event_store_aggregate_id ON event_store(aggregate_id);
      END IF;
      
      -- Index on correlation_id (partitioning column)
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'event_store' AND indexname = 'idx_event_store_correlation_id') THEN
        CREATE INDEX idx_event_store_correlation_id ON event_store(correlation_id);
      END IF;
      
      -- Index on recorded_on for time-based queries
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'event_store' AND indexname = 'idx_event_store_recorded_on') THEN
        CREATE INDEX idx_event_store_recorded_on ON event_store(recorded_on);
      END IF;
      
      -- Unique constraint on aggregate_id + aggregate_version
      IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_event_store_aggregate_version') THEN
        ALTER TABLE event_store ADD CONSTRAINT uq_event_store_aggregate_version UNIQUE (aggregate_id, aggregate_version);
      END IF;
      
      -- Indexes for idempotent reactions table
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'event_store_idempotent_reaction' AND indexname = 'idx_idempotent_reaction_id') THEN
        CREATE INDEX idx_idempotent_reaction_id ON event_store_idempotent_reaction(reaction_id);
      END IF;
      
      IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'event_store_idempotent_reaction' AND indexname = 'idx_idempotent_aggregate_id') THEN
        CREATE INDEX idx_idempotent_aggregate_id ON event_store_idempotent_reaction(aggregate_id);
      END IF;
    END;
  EOF

  depends_on = [
    postgresql_table.event_store,
    postgresql_table.event_store_idempotent_reaction
  ]
}

# Execute the index creation function
resource "postgresql_function_call" "create_indexes" {
  function_name = postgresql_function.create_event_store_indexes.name
  depends_on    = [postgresql_function.create_event_store_indexes]
}