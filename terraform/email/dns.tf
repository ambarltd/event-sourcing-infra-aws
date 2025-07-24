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