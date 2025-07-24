# SES Domain Identity using SESv2 (recommended)
resource "aws_sesv2_email_identity" "main" {
  provider       = aws.alt_region

  email_identity = var.domain_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

# SES Configuration Set (recommended for better management)
resource "aws_sesv2_configuration_set" "main" {
  provider       = aws.alt_region

  configuration_set_name = "${replace(var.route53_zone_name, ".", "-")}-config-set"

  delivery_options {
    tls_policy = "REQUIRE"
  }
}

# Optional: Custom MAIL FROM domain (recommended for better deliverability)
resource "aws_sesv2_email_identity_mail_from_attributes" "main" {
  provider       = aws.alt_region

  email_identity   = aws_sesv2_email_identity.main.email_identity
  mail_from_domain = "mail.${var.route53_zone_name}"

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}