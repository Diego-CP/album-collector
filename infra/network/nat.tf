# One Elastic IP per NAT gateway
resource "aws_eip" "nat" {
  count  = var.az_count
  domain = "vpc"
  tags   = { Name = "${var.project}-nat-eip-${local.azs[count.index]}" }
}

# One NAT gateway per AZ
resource "aws_nat_gateway" "this" {
  count         = var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = { Name = "${var.project}-nat-${local.azs[count.index]}" }
}
