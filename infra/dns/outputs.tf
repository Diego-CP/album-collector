output "name_servers" {
  value       = aws_route53_zone.primary.name_servers
  description = "Domain's nameservers."
}

output "zone_id" {
  value       = aws_route53_zone.primary.zone_id
  description = "Hosted zone ID."
}

output "domain_name" {
  value       = aws_route53_zone.primary.name
  description = "Domain name."
}

output "certificate_arn" {
  # Reads from the validation resource, not the cert directly
  value       = aws_acm_certificate_validation.app.certificate_arn
  description = "Validated ACM cert ARN."
}
