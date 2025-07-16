output "connection_string" {
  description = "The connection string for the MongoDB Atlas cluster"
  value       = var.mongodb_free_tier ? mongodbatlas_cluster.free_projection_store[0].connection_strings[0].standard : mongodbatlas_cluster.projection_store[0].connection_strings[0].standard
  sensitive   = true
}

output "srv_connection_string" {
  description = "The SRV connection string for the MongoDB Atlas cluster"
  value       = var.mongodb_free_tier ? mongodbatlas_cluster.free_projection_store[0].connection_strings[0].standard_srv : mongodbatlas_cluster.projection_store[0].connection_strings[0].standard_srv
  sensitive   = true
}

output "srv_connection_host" {
  description = "The SRV connection string for the MongoDB Atlas cluster"
  # remove any portion of the values that are supplied later on.
  value = var.mongodb_free_tier ? replace(
    mongodbatlas_cluster.free_projection_store[0].connection_strings[0].standard_srv,
    "/^mongodb\\+srv:\\/\\//",
    ""
  ) : replace(
    mongodbatlas_cluster.projection_store[0].connection_strings[0].standard_srv,
    "/^mongodb\\+srv:\\/\\//",
    ""
  )
  sensitive = true
}

output "cluster_id" {
  description = "The ID of the MongoDB Atlas cluster"
  value       = var.mongodb_free_tier ? mongodbatlas_cluster.free_projection_store[0].cluster_id :  mongodbatlas_cluster.projection_store[0].cluster_id
}

output "cluster_name" {
  description = "The name of the MongoDB Atlas cluster"
  value       = var.mongodb_free_tier ? mongodbatlas_cluster.free_projection_store[0].name : mongodbatlas_cluster.projection_store[0].name
}

output "projection_store_user" {
  value = random_string.mongodb_user.result
}

output "projection_store_password" {
  sensitive = true
  value     = random_password.mongodb_pass.result
}