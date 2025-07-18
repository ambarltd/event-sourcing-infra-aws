variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "emails_for_alerts" {
  type = list(string)
}

variable "backend_log_group_name" {
  type = string
}

variable "frontend_log_group_name" {
  type = string
}