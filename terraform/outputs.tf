##
# Domain and DNS Outputs - CRITICAL for external setup
##
output "domain_name_servers" {
  description = "Name servers for the hosted zone - CRITICAL: Configure these at your domain registrar"
  value       = module.domain.name_servers
}

##
# Application Endpoints
##
output "frontend_url" {
  description = "URL of the frontend application"
  value       = var.nameserver_records_completed ? "https://${var.frontend_domain}" : "DNS setup required - configure nameservers first"
}

output "backend_url" {
  description = "URL of the backend API"
  value       = var.nameserver_records_completed ? "https://${var.backend_application_domain}" : "DNS setup required - configure nameservers first"
}

##
# Container Registry Information
##
output "frontend_ecr_repository_url" {
  description = "ECR repository URL for frontend container images"
  value       = var.nameserver_records_completed ? module.frontend_image_registry[0].ecr_repository_repository_url : "Available after DNS setup"
}

output "backend_ecr_repository_url" {
  description = "ECR repository URL for backend container images"
  value       = var.nameserver_records_completed ? module.backend_image_registry[0].ecr_repository_repository_url : "Available after DNS setup"
}

output "frontend_github_role_arn" {
  description = "GitHub Actions assumable role ARN for frontend CI/CD"
  value       = var.nameserver_records_completed ? module.frontend_image_registry[0].github_assumable_role_read_write : "Available after DNS setup"
}

output "backend_github_role_arn" {
  description = "GitHub Actions assumable role ARN for backend CI/CD"
  value       = var.nameserver_records_completed ? module.backend_image_registry[0].github_assumable_role_read_write : "Available after DNS setup"
}

##
# Database Connection Information
##
output "event_store_endpoint" {
  description = "RDS PostgreSQL endpoint for event store"
  value       = var.nameserver_records_completed ? module.event_store[0].event_store_endpoint : "Available after DNS setup"
  sensitive   = true
}

output "mongodb_cluster_name" {
  description = "MongoDB Atlas cluster name for projections"
  value       = var.nameserver_records_completed ? module.projection_store[0].cluster_name : "Available after DNS setup"
}

output "mongodb_cluster_id" {
  description = "MongoDB Atlas cluster ID"
  value       = var.nameserver_records_completed ? module.projection_store[0].cluster_id : "Available after DNS setup"
}

##
# Storage Information
##
output "s3_bucket_name" {
  description = "S3 bucket name for object storage"
  value       = var.nameserver_records_completed ? module.object_storage[0].bucket_name : "Available after DNS setup"
}

output "s3_bucket_domain" {
  description = "S3 bucket domain name for direct access"
  value       = var.nameserver_records_completed ? module.object_storage[0].bucket_domain_name : "Available after DNS setup"
}

##
# Email Service Configuration
##
output "allowed_from_addresses" {
  description = "List of verified email addresses for SES sending"
  value       = var.nameserver_records_completed ? module.email[0].allowed_from_addresses : ["Available after DNS setup"]
}

##
# Infrastructure Information
##
output "vpc_id" {
  description = "VPC ID for the infrastructure"
  value       = var.nameserver_records_completed ? module.network[0].vpc_id : "Available after DNS setup"
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.nameserver_records_completed ? module.network[0].vpc_cidr_block : "Available after DNS setup"
}

output "availability_zones" {
  description = "Availability zones used by the infrastructure"
  value       = var.nameserver_records_completed ? module.network[0].availability_zones : ["Available after DNS setup"]
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = var.nameserver_records_completed ? module.network[0].public_subnet_ids : ["Available after DNS setup"]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = var.nameserver_records_completed ? module.network[0].private_subnet_ids : ["Available after DNS setup"]
}

##
# Service Information
##
output "frontend_cluster_name" {
  description = "ECS cluster name for frontend service"
  value       = var.nameserver_records_completed ? module.frontend_container_service[0].cluster_name : "Available after DNS setup"
}

output "backend_cluster_name" {
  description = "ECS cluster name for backend service"
  value       = var.nameserver_records_completed ? module.backend_container_service[0].cluster_name : "Available after DNS setup"
}

output "frontend_service_name" {
  description = "ECS service name for frontend"
  value       = var.nameserver_records_completed ? module.frontend_container_service[0].service_name : "Available after DNS setup"
}

output "backend_service_name" {
  description = "ECS service name for backend"
  value       = var.nameserver_records_completed ? module.backend_container_service[0].service_name : "Available after DNS setup"
}

##
# Monitoring
##
output "frontend_log_group_name" {
  description = "CloudWatch log group name for frontend service"
  value       = var.nameserver_records_completed ? module.frontend_container_service[0].cloudwatch_log_group_name : "Available after DNS setup"
}

output "backend_log_group_name" {
  description = "CloudWatch log group name for backend service"
  value       = var.nameserver_records_completed ? module.backend_container_service[0].cloudwatch_log_group_name : "Available after DNS setup"
}

##
# Setup Instructions
##
output "setup_instructions" {
  description = "Critical setup steps required after infrastructure deployment"
  value = {
    dns_setup = {
      description = "Configure these name servers at your domain registrar"
      name_servers = module.domain.name_servers
      domain = var.domain
      status = var.nameserver_records_completed ? "✅ Completed" : "🔄 Required - Configure nameservers then set nameserver_records_completed = true"
    }
    container_images = {
      description = "Push your application images to these ECR repositories"
      frontend_ecr = var.nameserver_records_completed ? module.frontend_image_registry[0].ecr_repository_repository_url : "Available after DNS setup"
      backend_ecr = var.nameserver_records_completed ? module.backend_image_registry[0].ecr_repository_repository_url : "Available after DNS setup"
      status = var.nameserver_records_completed ? "🔄 Ready for images" : "⏸️ Waiting for DNS setup"
    }
    github_actions = {
      description = "Configure these IAM roles in your GitHub Actions for CI/CD"
      frontend_role = var.nameserver_records_completed ? module.frontend_image_registry[0].github_assumable_role_read_write : "Available after DNS setup"
      backend_role = var.nameserver_records_completed ? module.backend_image_registry[0].github_assumable_role_read_write : "Available after DNS setup"
      status = var.nameserver_records_completed ? "🔄 Ready for CI/CD setup" : "⏸️ Waiting for DNS setup"
    }
    application_urls = {
      description = "Your application will be available at these URLs after DNS propagation"
      frontend = "https://${var.frontend_domain}"
      backend = "https://${var.backend_application_domain}"
      status = var.nameserver_records_completed ? "🔄 Deploy applications to activate" : "⏸️ Waiting for DNS setup"
    }
  }
}