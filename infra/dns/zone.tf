# Create the Route 53 public hosted zone
resource "aws_route53_zone" "primary" {
  name    = var.domain_name
  comment = "${var.project} public hosted zone"
}
