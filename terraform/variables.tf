##
# AWS related variables
##
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "application_account_aws_access_key" {
  description = "AWS Access Key"
  type = string
  sensitive = true
}

variable "application_account_aws_secret_key" {
  description = "AWS Secret Access Key"
  type = string
  sensitive = true
}

##
# MongoDB Atlas related variables
##
variable "mongodbatlas_public_key" {
  description = "MongoDB Atlas public API key"
  type        = string
  sensitive   = true
}

variable "mongodbatlas_private_key" {
  description = "MongoDB Atlas private API key"
  type        = string
  sensitive   = true
}

variable "mongodbatlas_project_id" {
  description = "MongoDB Atlas Project Identifier"
  type = string
}

##
# Ambar related variables
##
variable "ambar_api_key" {
  description = "API key for Ambar provider"
  type        = string
  sensitive   = true
}

variable "ambar_regional_endpoint" {
  description = "The regional api endpoint for Ambar to use"
  type = string
}

variable "destination_endpoints_to_descriptions" {
  description = "Map of projection and reaction endpoints with key as path and value as a description"
  type = map(string)
}

##
# Common configuration variables
##
variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "ambarltd"
}

variable "domain" {
  description = "Common domain name"
  type        = string
  default     = ""
}

##
# Frontend configuration variables
##
variable "github_frontend_repo" {
  description = "GitHub repository name for frontend"
  type        = string
  default     = ""
}

variable "github_frontend_repo_prod_branch" {
  description = "Production branch for frontend repository"
  type        = string
  default     = "main"
}

variable "frontend_image" {
  description = "Frontend container image"
  type        = string
  default     = ""
}

variable "frontend_application_port" {
  description = "Frontend application port"
  type        = number
  default     = 8081
}

variable "frontend_cpu_capacity" {
  description = "Frontend CPU capacity"
  type        = number
  default     = 256
}

variable "frontend_mem_capacity" {
  description = "Frontend memory capacity"
  type        = number
  default     = 512
}

variable "frontend_instance_count" {
  description = "Frontend instance count"
  type        = number
  default     = 0
}

variable "additional_frontend_domains" {
  description = "Additional frontend domains"
  type        = list(string)
  default     = []
}

variable "frontend_domain" {
  description = "Frontend domain name"
  type        = string
}

##
# Backend configuration variables
##
variable "github_backend_repo" {
  description = "GitHub repository name for backend"
  type        = string
  default     = ""
}

variable "github_backend_repo_prod_branch" {
  description = "Production branch for backend repository"
  type        = string
  default     = "main"
}

variable "backend_image" {
  description = "Backend container image"
  type        = string
  default     = ""
}

variable "backend_application_port" {
  description = "Backend application port"
  type        = number
  default     = 8080
}

variable "backend_cpu_capacity" {
  description = "Backend CPU capacity"
  type        = number
  default     = 512
}

variable "backend_mem_capacity" {
  description = "Backend memory capacity"
  type        = number
  default     = 1024
}

variable "backend_instance_count" {
  description = "Backend instance count"
  type        = number
  default     = 0
}

variable "from_email" {
  description = "From email address"
  type        = string
  default     = ""
}

variable "backend_application_domain" {
  description = "Backend application domain name"
  type        = string
}

##
# Monitoring configuration variables
##
variable "emails_for_alerts" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
}