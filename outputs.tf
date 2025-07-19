##
# Application Endpoints
##
output "frontend_url" {
  description = "URL of the frontend application"
  value       = "https://${var.top_level_domain}"
}

output "backend_url" {
  description = "URL of the backend API"
  value       = "https://api.${var.top_level_domain}"
}

##
# Container Registry Information
##
output "frontend_ecr_repository_url" {
  description = "ECR repository URL for frontend container images"
  value       = module.frontend_image_registry.ecr_repository_repository_url
}

output "backend_ecr_repository_url" {
  description = "ECR repository URL for backend container images"
  value       = module.backend_image_registry.ecr_repository_repository_url
}