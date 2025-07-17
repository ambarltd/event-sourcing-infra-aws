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

variable "mongodbatlas_free_tier" {
  description = "If the projection store should use the M0 or M10 cluster size"
  type = bool
  default = false
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
  description = "List of destinations objects describing endpoint path and a description"
  type = list(object({
    path        = string
    description = string
  }))
}

##
# Frontend configuration variables
##

variable "frontend_image" {
  description = "Frontend container image"
  type        = string
}

variable "frontend_application_port" {
  description = "Frontend application port"
  type        = number
  default     = 8080
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

variable "domain" {
  description = "Domain name for frontend hosting"
  type        = string
}

##
# Backend configuration variables
##

variable "backend_image" {
  description = "Backend container image"
  type        = string
}

variable "backend_application_port" {
  description = "Backend application port"
  type        = number
  default     = 3000
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
}

##
# Monitoring configuration variables
##
variable "emails_for_alerts" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
}

##
# Deployment management variables
##
variable "nameserver_records_completed" {
  description = "CRITICAL: Only the Route53 HostedZone will be created until this variable is set to true. Use the NameServer dns entries from the terraform outputs to update the registrar where your domain is managed to allow for further resources to be created using it."
  type = bool
  default = false
}

variable "event_store_configured" {
  description = "If the application has been deployed at least once and successfully connected to and configured the event store for ambar use."
  type = bool
  default = false
}