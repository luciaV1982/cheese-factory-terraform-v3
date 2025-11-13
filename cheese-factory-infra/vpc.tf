data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = ["10.20.1.0/24","10.20.2.0/24","10.20.3.0/24"]
  private_subnets = ["10.20.101.0/24","10.20.102.0/24","10.20.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags  = merge(local.common_tags, { Tier = "public" })
  private_subnet_tags = merge(local.common_tags, { Tier = "private" })

  tags = local.common_tags
}
