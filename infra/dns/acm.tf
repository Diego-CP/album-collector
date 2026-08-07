# Creates an ACM cert in PENDING_VALIDATION state
resource "aws_acm_certificate" "app" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  # New cert is created and validated before the old one is destroyed
  lifecycle {
    create_before_destroy = true
  }
}

# Create the CNAME records ACM asked for in our DNS
resource "aws_route53_record" "acm_validation" {
  # One entry today (apex only). ACM emits one validation option per domain name on the
  # cert (apex + SANs) so this loop is future-proofing
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = aws_route53_zone.primary.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Wait for ACM to report cert validated (ISSUED state) for each record
# Note that this doesn't create infra, it just waits so downstream consumers 
# get a validated certificate
resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
