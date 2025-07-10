# Project Information
variable "region" {
  description = "AWS region"
  type        = string
}

variable "frontend_domain" {
  description = "Domain name for primary SSL certificate"
  type        = string
}

variable "backend_endpoint" {
  type = string
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/"
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

variable "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
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

variable "additional_domains" {
  description = "List of domains to create certificates for"
  type        = list(string)
}