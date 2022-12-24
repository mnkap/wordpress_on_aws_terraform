module "rds" {
  source                 = "terraform-aws-modules/rds/aws"
  identifier             = "mydb"
  db_name                = "wp_db"
  engine                 = "mysql"
  engine_version         = "5.7.33"
  major_engine_version   = "5.7"
  parameter_group_name   = "default-mysql57"
  multi_az               = false
  instance_class         = "db.t3.micro"
  storage_type           = "standard"
  family                 = "mysql5.7"
  skip_final_snapshot    = true
  allocated_storage      = 10
  create_db_subnet_group = false
  create_random_password = false
  username               = "dbadmin"
  password               = local.wprdspassword
  db_subnet_group_name   = aws_db_subnet_group.main.name
  subnet_ids             = [data.terraform_remote_state.level1_wordpress.outputs.private_subnets[0], data.terraform_remote_state.level1_wordpress.outputs.private_subnets[1]]
  vpc_security_group_ids = [aws_security_group.rds.id]
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = data.terraform_remote_state.level1_wordpress.outputs.private_subnets


  tags = {
    Name = "Education"
  }
}

resource "aws_security_group" "rds" {
  name   = "education_rds"
  vpc_id = data.terraform_remote_state.level1_wordpress.outputs.vpc_id


  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "education_rds"
  }
}