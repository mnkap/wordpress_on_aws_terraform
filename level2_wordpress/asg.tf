module "asg" {
  source        = "terraform-aws-modules/autoscaling/aws"
  version       = "6.5.3"
  image_id      = data.aws_ami.amazonlinux.id
  instance_type = "t2.micro"
  user_data     = base64encode(data.template_file.test.rendered)

  name                = "webservers-asg"
  health_check_type   = "EC2"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = [data.terraform_remote_state.level1_wordpress.outputs.private_subnets[0], data.terraform_remote_state.level1_wordpress.outputs.private_subnets[1]]
  security_groups     = [aws_security_group.load_balancer.id]
  target_group_arns   = ["arn:aws:elasticloadbalancing:us-east-1:182678615463:targetgroup/pref-20221223142242359400000004/e3d3f81de3715e11"]

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

data "template_file" "test" {
  template = <<EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install -y httpd mariadb-server
  sudo systemctl start httpd && sudo systemctl enable httpd
  sudo systemctl start mariadb
  sudo usermod -a -G apache ec2-user
  sudo chown -R ec2-user:apache /var/www
  sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
  find /var/www -type f -exec sudo chmod 0664 {} \;
  sudo yum install epel-release yum-utils wget -y
  sudo amazon-linux-extras enable php8.0
  sudo yum clean metadata && sudo yum install yum install php-cli php-pdo php-fpm php-mysqlnd -y
  sudo wget https://wordpress.org/latest.tar.gz
  sudo tar -xzvf latest.tar.gz
  sudo cp -r wordpress/* /var/www/html/
  sudo chown -R apache:apache /var/www/html
  sudo systemctl restart httpd
  EOF
}