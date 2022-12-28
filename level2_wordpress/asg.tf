module "asg" {
  source        = "terraform-aws-modules/autoscaling/aws"
  version       = "6.5.3"
  image_id      = data.aws_ami.amazonlinux.id
  instance_type = "t2.micro"
  user_data     = base64encode(data.template_file.user_data.rendered)

  name                = "webservers-asg"
  health_check_type   = "EC2"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = [data.terraform_remote_state.level1_wordpress.outputs.private_subnets[0], data.terraform_remote_state.level1_wordpress.outputs.private_subnets[1]]
  security_groups     = [aws_security_group.load_balancer.id]
  target_group_arns   = ["arn:aws:elasticloadbalancing:us-east-1:182678615463:targetgroup/pref-20221228133753128300000003/5081d0b73557f13c"]

  create_iam_instance_profile = true
  iam_role_name               = "example-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"


  iam_role_tags = {
    CustomIamRole = "Yes"
  }


  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true


  filter {
    name   = "state"
    values = ["available"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }


  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]


}

resource "aws_security_group" "private" {
  name        = "${var.env_code}-private"
  description = "Allow VPC traffic"
  vpc_id      = data.terraform_remote_state.level1_wordpress.outputs.vpc_id


  ingress {
    description = "SSH from public"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["87.255.216.86/32"]
  }


  ingress {
    description     = "HTTP from load balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.env_code}-public"
  }
}

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


data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
  vars = {
    db_username      = "dbadmin"
    db_user_password = local.wprdspassword
    db_name          = "wp_db"
    db_RDS           = module.rds.db_instance_endpoint
  }
}
