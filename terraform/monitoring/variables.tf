variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "emails_for_alerts" {
  description = "List of email addresses to receive monitoring alerts"
  type = list(string)
}

variable "backend_log_group_name" {
  description = "Name of the CloudWatch log group for backend application logs"
  type = string
}

variable "frontend_log_group_name" {
  description = "Name of the CloudWatch log group for frontend application logs"
  type = string
}