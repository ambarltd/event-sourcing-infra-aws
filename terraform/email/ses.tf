# SES Domain Identity (if using SES)
resource "aws_ses_domain_identity" "main" {
  provider = aws.ses
  domain   = var.route53_zone_name
}

# SES DKIM tokens
resource "aws_ses_domain_dkim" "main" {
  provider = aws.ses
  domain   = aws_ses_domain_identity.main.domain
}

# SES Domain verification record
resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${var.route53_zone_name}"
  type    = "TXT"
  ttl     = 300
  records = [aws_ses_domain_identity.main.verification_token]
}

# SES DKIM records
resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.route53_zone_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}
