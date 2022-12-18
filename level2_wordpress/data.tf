data "terraform_remote_state" "level1" {
  backend = "s3"

  config = {
    bucket = "terraform-remote-state-aws-wordpress"
    key    = "level1_wordpress.tfstate"
    region = "us-east-1"
  }
}