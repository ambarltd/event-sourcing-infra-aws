output "connection_string" {
  description = "The connection string for the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.projection_store.connection_strings[0].standard
  sensitive   = true
}

output "srv_connection_string" {
  description = "The SRV connection string for the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.projection_store.connection_strings[0].standard_srv
  sensitive   = true
}

output "srv_connection_host" {
  description = "The SRV connection string for the MongoDB Atlas cluster"
  # remove any portion of the values that are supplied later on.
  value = replace(
    mongodbatlas_cluster.projection_store.connection_strings[0].standard_srv,
    "/^mongodb\\+srv:\\/\\//",
    ""
  )
  sensitive = true
}

output "cluster_id" {
  description = "The ID of the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.projection_store.cluster_id
}

output "cluster_name" {
  description = "The name of the MongoDB Atlas cluster"
  value       = mongodbatlas_cluster.projection_store.name
}

output "projection_store_user" {
  value = random_string.mongodb_user.result
}

output "projection_store_password" {
  sensitive = true
  value     = random_password.mongodb_pass.result
}