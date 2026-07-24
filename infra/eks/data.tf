data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "album-collector-tfstate-822902368026"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}
