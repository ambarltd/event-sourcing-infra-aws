# SES Domain outputs
output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_sesv2_email_identity.main.arn
}

output "ses_domain_verification_token" {
  description = "Domain verification token"
  value       = aws_sesv2_email_identity.main.dkim_signing_attributes[0].tokens[0]
}

output "ses_dkim_tokens" {
  description = "DKIM tokens for domain verification"
  value       = aws_sesv2_email_identity.main.dkim_signing_attributes[0].tokens
}

output "ses_configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_sesv2_configuration_set.main.configuration_set_name
}

# Outputs for IAM role
output "email_user_role_arn" {
  description = "ARN of the IAM role for SES email sending"
  value       = aws_iam_role.email_user.arn
}

output "email_user_role_name" {
  description = "Name of the IAM role for SES email sending"
  value       = aws_iam_role.email_user.name
}

output "email_user_instance_profile_name" {
  description = "Name of the instance profile for EC2 instances that need to send email"
  value       = aws_iam_instance_profile.email_user.name
}

output "email_user_instance_profile_arn" {
  description = "ARN of the instance profile for EC2 instances that need to send email"
  value       = aws_iam_instance_profile.email_user.arn
}

# SMTP Configuration outputs
output "smtp_host" {
  description = "SMTP host for SES email sending"
  value       = "email-smtp.${local.ses_region}.amazonaws.com"
}

output "smtp_port" {
  description = "SMTP port for SES email sending (587 for TLS)"
  value       = "587"
}

# SMTP User credentials
output "smtp_username" {
  description = "SMTP username for SES email sending"
  value       = aws_iam_access_key.smtp_user.id
}

output "smtp_password" {
  description = "SMTP password for SES email sending"
  value       = aws_iam_access_key.smtp_user.ses_smtp_password_v4
  sensitive   = true
}