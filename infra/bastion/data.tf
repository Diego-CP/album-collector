data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "album-collector-tfstate-822902368026"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}
