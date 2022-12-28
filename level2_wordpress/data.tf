data "terraform_remote_state" "level1_wordpress" {
  backend = "s3"


  config = {
    bucket = "terraform-remote-state-aws-wordpress"
    key    = "level1_wordpress.tfstate"
    region = "us-east-1"
  }
}


data "terraform_remote_state" "level2_wordpress" {
  backend = "s3"


  config = {
    bucket = "terraform-remote-state-aws-wordpress"
    key    = "level2_wordpress.tfstate"
    region = "us-east-1"
  }
}