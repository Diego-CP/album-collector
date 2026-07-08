data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # First N AZs in the region (us-east-1a, us-east-1b, ...)
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # Required by EKS
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw" }
}
