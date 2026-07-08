# PUBLIC subnets - ALB and the NAT gateways. One per AZ
# cidrsubnet(cidr, 4, i) creates /20 blocks from the /16:
# index 0 -> 10.0.0.0/20, index 1 -> 10.0.16.0/20
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true # things launched here get a public IP

  tags = {
    Name = "${var.project}-public-${local.azs[count.index]}"
    # Lets the AWS Load Balancer Controller auto-discover these subnets for
    # INTERNET-FACING load balancers
    "kubernetes.io/role/elb" = "1"
  }
}

# PRIVATE subnets — EKS nodes/pods and Aurora. One per AZ
# Offset by az_count so the /20 blocks don't collide with the public ones:
# index 0 -> 10.0.32.0/20, index 1 -> 10.0.48.0/20
# EKS VPC CNI provides VPC IP per POD
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, var.az_count + count.index)
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.project}-private-${local.azs[count.index]}"
    # For INTERNAL load balancers (service-to-service), discovered the same way
    "kubernetes.io/role/internal-elb" = "1"
  }
}
