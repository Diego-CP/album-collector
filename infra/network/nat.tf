# One Elastic IP per NAT gateway (if enabled)
resource "aws_eip" "nat" {
  count  = var.enable_nat ? var.az_count : 0
  domain = "vpc"
  tags   = { Name = "${var.project}-nat-eip-${local.azs[count.index]}" }
}

# One NAT gateway per AZ (if enabled)
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat ? var.az_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = { Name = "${var.project}-nat-${local.azs[count.index]}" }
}
