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
  template = <<EOF
 #!/bin/bash
  echo export db_name="wp_db" | sudo tee -a /etc/profile
  echo export db_username="dbadmin" | sudo tee -a /etc/profile
  echo export db_RDS="${module.rds.db_instance_endpoint}" | sudo tee -a /etc/profile
  echo export db_user_password="${local.wprdspassword}" | sudo tee -a /etc/profile
  source /etc/profile 
  sudo yum update -y
  sudo yum install -y httpd
  sudo yum install -y mariadb-server
  sudo systemctl enable mariadb 
  sudo systemctl start mariadb
  sudo amazon-linux-extras enable php8.0
  sudo yum clean metadata && sudo yum install yum install php-gd php-cli php-pdo php-fpm php-mysqlnd -y
  sudo systemctl start httpd && sudo systemctl enable httpd
  sudo usermod -a -G apache ec2-user
  sudo chown -R ec2-user:apache /var/www
  sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
  find /var/www -type f -exec sudo chmod 0664 {} \;
  sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  sudo chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
  sudo chmod 777 /var/www/html
  wp core download --path=/var/www/html --allow-root
  wp config create --dbname=$db_name --dbuser=$db_username --dbpass=$db_user_password --dbhost=$db_RDS --path=/var/www/html --allow-root <<PHP
  define( 'FS_METHOD', 'direct' );
  define('WP_MEMORY_LIMIT', '128M');
  PHP
  sudo chown -R apache:apache /var/www/html
  sudo systemctl restart httpd
  EOF
}

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
  target_group_arns   = [module.alb.target_group_arns[0]]
 

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

 depends_on = [
   module.rds
 ]
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



