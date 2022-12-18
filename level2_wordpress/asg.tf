module "asg" {
  source        = "terraform-aws-modules/autoscaling/aws"
  version       = "6.5.3"
  image_id      = data.aws_ami.amazonlinux.id
  instance_type = "t2.micro"

  name                = "webservers-asg"
  health_check_type   = "EC2"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = [data.terraform_remote_state.level1.outputs.private_subnets[0], data.terraform_remote_state.level1.outputs.private_subnets[1]]
  security_groups     = [aws_security_group.load_balancer.id]
  target_group_arns   = ["arn:aws:elasticloadbalancing:us-east-1:182678615463:targetgroup/pref-20221218084448805300000001/e0c42f15bd4ae5b6"]

  create_iam_instance_profile = true
  iam_role_name               = "example-asg"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
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
  vpc_id      = data.terraform_remote_state.level1.outputs.vpc_id

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
