module "msk_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "msk_sg"
  description = "Security group for MSK"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      source_security_group_id = module.asg[0].security_group_id
      description              = "Allow traffic from producer_sg"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "-1"
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_s3_bucket" "msk_logs_bucket" {
  bucket = "${local.unique_prefix}-msk-logs"

  tags = merge(local.tags, {
    Name = "${local.unique_prefix}-msk-logs"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "msk_logs_bucket_encryption" {
  bucket = aws_s3_bucket.msk_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "msk_logs_bucket_versioning" {
  bucket = aws_s3_bucket.msk_logs_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "msk_logs_bucket_public_access" {
  bucket = aws_s3_bucket.msk_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_msk_cluster" "msk_cluster" {
  cluster_name           = "${local.unique_prefix}-msk-cluster"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = var.number_of_brokers

  enhanced_monitoring = "PER_TOPIC_PER_PARTITION"
  broker_node_group_info {
    instance_type   = var.kafka_broker_instance_type
    client_subnets  = module.vpc.private_subnets
    security_groups = [module.msk_sg.security_group_id]
  }

  # Logging configuration for MSK cluster to S3
  logging_info {
    broker_logs {
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.msk_logs_bucket.id
        prefix  = "msk-logs"
      }
    }
  }

  # Enable encryption at rest and in transit
  encryption_info {
    # encryption_at_rest_kms_key_arn = aws_kms_key.kafka_kms_key.arn

    encryption_in_transit {
      client_broker = "PLAINTEXT"
      in_cluster    = true
    }
  }

  client_authentication {
    unauthenticated = true
    sasl {
      iam   = false
      scram = false
    }
    tls {}
  }

  tags = merge(local.tags,
    {
      Name = "${local.unique_prefix}-msk-cluster"
    }
  )
}

resource "aws_ssm_parameter" "kafka_connect_string" {
  name  = "/cantina/kafka/connect_string"
  type  = "String"
  value = aws_msk_cluster.msk_cluster.bootstrap_brokers
}