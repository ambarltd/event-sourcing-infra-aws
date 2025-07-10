# Output the name servers - CRITICAL for domain registrar setup
output "name_servers" {
  description = "Name servers for the hosted zone - configure these at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

# Output the hosted zone ID - needed for ACM certificate validation and other AWS services
output "hosted_zone_id" {
  description = "Route53 Hosted Zone ID - needed for ACM certificate DNS validation and other AWS services"
  value       = aws_route53_zone.main.zone_id
}

# Output the zone name - useful for referencing in other resources
output "zone_name" {
  description = "The hosted zone domain name"
  value       = aws_route53_zone.main.name
}

# Output for ACM certificate management (when managed elsewhere)
output "domain_name" {
  description = "Domain name for ACM certificate creation in other modules"
  value       = var.domain_name
}

# Output for wildcard domain (commonly needed for ACM)
output "wildcard_domain" {
  description = "Wildcard domain name for ACM certificate creation"
  value       = "*.${var.domain_name}"
}
