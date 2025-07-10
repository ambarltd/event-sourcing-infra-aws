variable "email_user_role_name" {
  description = "Name for the IAM role that will send emails"
  type        = string
  default     = "ses-email-sender"
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

variable "allowed_from_addresses" {
  description = "List of allowed 'from' email addresses for SES sending"
  type        = list(string)
  default     = []
}