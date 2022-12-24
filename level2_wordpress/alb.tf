module "alb" {
  source          = "terraform-aws-modules/alb/aws"
  version         = "8.2.1"
  name            = "awslb"
  security_groups = [aws_security_group.load_balancer.id]
  vpc_id          = data.terraform_remote_state.level1_wordpress.outputs.vpc_id
  subnets         = [data.terraform_remote_state.level1_wordpress.outputs.public_subnets[0], data.terraform_remote_state.level1_wordpress.outputs.public_subnets[1]]


  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
    }
  ]


  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}

resource "aws_security_group" "load_balancer" {
  name        = "${var.env_code}-load-balancer"
  description = "Allow port 80 TCP inbound to ELB"
  vpc_id      = data.terraform_remote_state.level1_wordpress.outputs.vpc_id


  ingress {
    description = "HTTPS from public"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "HTTP from public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "ALL"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.env_code}-load_balancer"
  }
}
