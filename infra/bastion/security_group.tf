resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion"
  description = "SSM bastion. No inbound: Session Manager is outbound-only."
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # To be used by: SSM control channel (443 to AWS endpoints via IGW)
  # and forwarded MySQL traffic (3306 to Aurora inside the VPC).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-bastion-sg" }
}
