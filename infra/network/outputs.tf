# Later stacks (EKS, Aurora, ALB) read these via a terraform_remote_state data
# source pointed at this stack's state key ("network/terraform.tfstate")

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC id."
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet ids (ALB, NAT gateways)."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet ids (EKS nodes/pods, Aurora)."
}

output "availability_zones" {
  value       = local.azs
  description = "AZs in use."
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.this[*].id
  description = "NAT gateway ids (one per AZ)."
}

output "private_route_table_ids" {
  value       = aws_route_table.private[*].id
  description = "Private route table ids (for S3 gateway endpoints)."
}
