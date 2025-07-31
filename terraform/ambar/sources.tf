resource "ambar_data_source" "event_store" {
  data_source_type = "postgres"
  description      = "Postgres Event Store DataSource"
  # data_source_config key-values depend on the type of DataSource being created.
  # See Ambar docs (https://docs.ambar.cloud/) for more details.
  # We will use a default postgres datasource for this template.
  data_source_config = {
    "hostname" : var.data_source_host,
    "hostPort" : 5432,
    "username" : var.data_source_user,
    "password" : var.data_source_password,
    "databaseName" : "postgres",
    "tableName" : "event_store",
    "publicationName" : var.publication_name,
    "partitioningColumn" : "correlation_id",
    "serialColumn" : "id",
    # columns should include all columns to be read from the database
    # including the partition and serial columns
    "columns" : "id,event_id,event_name,aggregate_id,aggregate_version,json_payload,json_metadata,recorded_on,causation_id,correlation_id"
  }
}