output "event_store_endpoint" {
  value = module.database.cluster_endpoint
}

output "event_store_user" {
  sensitive = true
  value     = random_string.db_user.result
}

output "event_store_password" {
  sensitive = true
  value     = random_password.db_pass.result
}