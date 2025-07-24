variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "domain_name" {
  description = "The domain name for email sending restrictions"
  type        = string
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name from the route53 module"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID from the route53 module"
  type        = string
}

variable "allowed_from_address" {
  description = "List of allowed 'from' email addresses for SES sending"
  type        = string
}