resource "aws_instance" "bastion" {
  # nonsensitive() lets the AMI ID show in the plan
  ami           = nonsensitive(data.aws_ssm_parameter.al2023_arm64.value)
  instance_type = var.instance_type

  # PUBLIC subnet - SSM agent reaches AWS endpoints over an IGW
  subnet_id              = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  tags = { Name = "${var.project}-bastion" }
}
