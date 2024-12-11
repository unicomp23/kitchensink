module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.unique_prefix}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  # private_subnet_names = [for k, v in local.azs : "Private-${k}"]
  intra_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = local.tags
}

module "asg" {
  source = "../modules/ec2-asg"

  for_each = { for idx, cfg in local.asg_configs : idx => cfg }

  env              = var.environment
  customer         = var.customer
  name_prefix      = each.value.name_prefix
  ami_id           = each.value.ami_id
  instance_type    = each.value.instance_type
  ebs_volume_size  = each.value.ebs_volume_size
  desired_capacity = each.value.desired_capacity
  max_size         = each.value.max_size
  min_size         = each.value.min_size
  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = module.vpc.vpc_cidr_block
  subnet_ids       = each.value.subnet_ids
}

module "code_deploy" {
  source = "../modules/code-deploy"
  env    = lower(var.environment)

  # Pass in individual app names to create CodeDeploy resources for each
  codedeploy_apps = ["${local.unique_prefix}-producer", "${local.unique_prefix}-consumer"]

  # Create Code Deploy deployment group with individual autoscaling groups
  autoscaling_group_names = {
    for idx, cfg in local.asg_configs : cfg.name_prefix => module.asg[idx].autoscaling_group_name
  }
}
