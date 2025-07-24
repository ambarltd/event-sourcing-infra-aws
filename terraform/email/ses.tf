# SES Domain Identity using SESv2 (recommended)
resource "aws_sesv2_email_identity" "main" {
  provider       = aws.ses
  email_identity = var.route53_zone_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

# SES Configuration Set (recommended for better management)
resource "aws_sesv2_configuration_set" "main" {
  provider               = aws.ses
  configuration_set_name = "${replace(var.route53_zone_name, ".", "-")}-config-set"

  delivery_options {
    tls_policy = "Require"
  }
}

# Domain verification record
resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses"
  type    = "TXT"
  ttl     = 300
  records = [aws_sesv2_email_identity.main.dkim_signing_attributes[0].tokens[0]]
}

# DKIM CNAME records for email authentication
resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name    = "${aws_sesv2_email_identity.main.dkim_signing_attributes[0].tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_sesv2_email_identity.main.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

# Optional: Custom MAIL FROM domain (recommended for better deliverability)
resource "aws_sesv2_email_identity_mail_from_attributes" "main" {
  provider         = aws.ses
  email_identity   = aws_sesv2_email_identity.main.email_identity
  mail_from_domain = "mail.${var.route53_zone_name}"

  behavior_on_mx_failure = "UseDefaultValue"
}

# MX record for custom MAIL FROM domain
resource "aws_route53_record" "ses_mail_from_mx" {
  zone_id = var.route53_zone_id
  name    = "mail"
  type    = "MX"
  ttl     = 300
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

# SPF record for the MAIL FROM domain
resource "aws_route53_record" "ses_mail_from_spf" {
  zone_id = var.route53_zone_id
  name    = "mail"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

# Outputs for verification
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