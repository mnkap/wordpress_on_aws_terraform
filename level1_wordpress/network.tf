module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  cidr               = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  azs                = var.vpc_azs
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
}
