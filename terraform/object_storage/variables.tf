variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "lifecycle_enabled" {
  description = "Enable lifecycle configuration for the S3 bucket"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which non-current object versions will expire"
  type        = number
  default     = 90
}

variable "frontend_cors_domain" {
  type = string
}