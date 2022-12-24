data "aws_secretsmanager_secret" "wprdspassword" {
  name = "wp/rds/password"
}

data "aws_secretsmanager_secret_version" "wprdspassword" {
  secret_id = data.aws_secretsmanager_secret.wprdspassword.id
}

locals {
  wprdspassword = jsondecode(data.aws_secretsmanager_secret_version.wprdspassword.secret_string)["password"]
}