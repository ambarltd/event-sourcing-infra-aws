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
}

variable "frontend_cpu_capacity" {
  description = "Frontend CPU capacity"
  type        = number
}

variable "frontend_mem_capacity" {
  description = "Frontend memory capacity"
  type        = number
}

variable "frontend_instance_count" {
  description = "Frontend instance count"
  type        = number
}

variable "additional_frontend_domains" {
  description = "Additional frontend domains"
  type        = list(string)
}

variable "top_level_domain" {
  description = "Domain name for frontend hosting"
  type        = string
}

variable "frontend_application_domain_prefix" {
  description = "A prefix (if any) to apply to the domain for hosting the frontend portion of the application (E.G. 'app' for app.domain.com)"
  type = string
}

variable "hosted_zone_id" {
  description = "ID of the hosted zone for the domain"
  type = string
}

variable "hosted_zone_name" {
  description = "Name of the hosted zone for the domain"
  type = string
}

##
# Backend configuration variables
##
variable "backend_image" {
  description = "Backend container image"
  type        = string
}

variable "backend_application_domain_prefix" {
  description = "A prefix (if any) to apply to the domain for hosting the backend portion of the application (E.G. 'api' for api.domain.com)"
  type = string
}

variable "backend_application_port" {
  description = "Backend application port"
  type        = number
}

variable "backend_cpu_capacity" {
  description = "Backend CPU capacity"
  type        = number
}

variable "backend_mem_capacity" {
  description = "Backend memory capacity"
  type        = number
}

variable "backend_instance_count" {
  description = "Backend instance count"
  type        = number
}

variable "from_email" {
  description = "Identity to send emails from the backend as (E.G. 'noreply' for noreply@domain.com"
  type        = string
}

##
# Monitoring configuration variables
##
variable "emails_for_alerts" {
  description = "List of email addresses for alerts"
  type        = list(string)
}

variable "event_store_configured" {
  description = "If the application has been deployed at least once and successfully connected to and configured the event store for ambar use."
  type = bool
}

variable "environment_name" {
  description = "Resource name prefix for easy identification and allowing multiple template deployments to one AWS account."
  type = string
}