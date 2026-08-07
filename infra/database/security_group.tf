resource "aws_security_group" "aurora" {
  name        = "${var.project}-aurora"
  description = "Aurora MySQL access"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # Would replace with EKS SG in prod, where the SG is not constantly
  # torn down
  ingress {
    description = "MySQL from within the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-aurora-sg" }
}
