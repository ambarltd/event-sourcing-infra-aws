variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "backend_domain" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/health"
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

# Container Configuration
variable "container_image" {
  description = "Docker image for the application container"
  type        = string
}

variable "ecr_repository_name" {
  description = "Amazon ECR repository name where the image is hosted"
  type        = string
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "CPU units for the container (1024 = 1 vCPU)"
  type        = number
}

variable "container_memory" {
  description = "Memory for the container in MiB"
  type        = number
}

# Service Configuration
variable "desired_count" {
  description = "Desired number of container instances to run"
  type        = number
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 300
}

# S3 Access
variable "blob_storage_bucket_name" {
  description = "Name of the S3 bucket for blob storage"
  type        = string
}

variable "blob_storage_bucket_arn" {
  description = "ARN of the S3 bucket for blob storage"
  type        = string
}

variable "s3_access_key_id" {
  description = "Access key ID for the S3 user"
  type        = string
  sensitive   = true
}

variable "s3_secret_access_key" {
  description = "Secret access key for the S3 user"
  type        = string
  sensitive   = true
}

# Event Store Configuration
variable "event_store_endpoint" {
  description = "Endpoint for the Event Store RDS instance"
  type        = string
}

variable "event_store_port" {
  description = "Port for the Event Store RDS instance"
  type        = number
}

variable "event_store_username" {
  description = "Username for the Event Store database"
  type        = string
}

variable "event_store_password" {
  description = "Password for the Event Store database"
  type        = string
  sensitive   = true
}

variable "event_store_replication_username" {
  description = "Username for the Event Store database"
  type        = string
  default     = ""
}

variable "event_store_replication_password" {
  description = "Password for the Event Store database"
  type        = string
  sensitive   = true
  default     = ""
}

# MongoDB Configuration
variable "mongodb_host" {
  description = "Host for the MongoDB projection store"
  type        = string
}

variable "mongodb_port" {
  description = "Port for the MongoDB projection store"
  type        = number
}

variable "mongodb_username" {
  description = "Username for MongoDB projection store"
  type        = string
}

variable "mongodb_password" {
  description = "Password for MongoDB projection store"
  type        = string
  sensitive   = true
}

# SMTP Configuration
variable "smtp_host" {
  description = "SMTP host for sending emails"
  type        = string
}

variable "smtp_port" {
  description = "SMTP port for sending emails"
  type        = string
}

variable "smtp_username" {
  description = "SMTP username for authentication"
  type        = string
}

variable "smtp_password" {
  description = "SMTP password for authentication"
  type        = string
  sensitive   = true
}

# Other
variable "frontend_domain" {
  type = string
}

variable "smtp_from_email" {
  type = string
}

# DNS Configuration for ACM certificate validation
variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string
}

variable "environment_variables" {
  description = "Additional environment variables to configure for the service, beside base Ambar configs."
  type = list(object({
    name  = string
    value = string
  }))
}