locals {
  unique_prefix = "${var.customer}-${var.environment}"
  # azs           = slice(sort(data.aws_availability_zones.available.zone_ids), 0, 3) # due to msk limitations using az-ids
  azs      = slice(sort(data.aws_availability_zones.available.names), 0, 3)
  vpc_cidr = "10.0.0.0/16"
  tags = {
    CreatedBy   = "Terraform"
    Environment = var.environment
    GithubRepo  = "kafka-poc"
    GithubOrg   = "airtimemedia"
  }

  asg_configs = [
    {
      name_prefix = "${local.unique_prefix}-producer"
      # ami_id           = data.aws_ami.amazon_linux_2023.id
      ami_id           = "ami-0b8bed09ee7ea7709"
      instance_type    = var.producer_instance_type
      ebs_volume_size  = 8
      desired_capacity = var.producer_desired_capacity
      max_size         = var.producer_max_size
      min_size         = var.producer_min_size
      subnet_ids       = module.vpc.private_subnets
    },
    {
      name_prefix = "${local.unique_prefix}-consumer"
      # ami_id           = data.aws_ami.amazon_linux_2023.id
      ami_id           = "ami-0a649fec795114b1e"
      instance_type    = var.consumer_instance_type
      ebs_volume_size  = 8
      desired_capacity = var.consumer_desired_capacity
      max_size         = var.consumer_max_size
      min_size         = var.consumer_min_size
      subnet_ids       = module.vpc.private_subnets
    },
    {
      name_prefix      = "${local.unique_prefix}-node-producer"
      ami_id           = "ami-061b3fb3c79e18309"
      instance_type    = "c5.4xlarge"
      ebs_volume_size  = 50
      desired_capacity = 1
      max_size         = 1
      min_size         = 1
      subnet_ids       = module.vpc.private_subnets
    },
    {
      name_prefix      = "${local.unique_prefix}-node-consumer"
      ami_id           = "ami-061b3fb3c79e18309"
      instance_type    = "c5.4xlarge"
      ebs_volume_size  = 50
      desired_capacity = 1
      max_size         = 1
      min_size         = 1
      subnet_ids       = module.vpc.private_subnets
    },
    {
      name_prefix      = "${local.unique_prefix}-node-producer-jd"
      ami_id           = "ami-061b3fb3c79e18309"
      instance_type    = "c5.4xlarge"
      ebs_volume_size  = 50
      desired_capacity = 100
      max_size         = 100
      min_size         = 0
      subnet_ids       = module.vpc.private_subnets
    },
    {
      name_prefix      = "${local.unique_prefix}-node-consumer-jd"
      ami_id           = "ami-061b3fb3c79e18309"
      instance_type    = "c5.4xlarge"
      ebs_volume_size  = 50
      desired_capacity = 2
      max_size         = 2
      min_size         = 0
      subnet_ids       = module.vpc.private_subnets
    }
  ]
}
