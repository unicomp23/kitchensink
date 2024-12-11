locals {
  unique_prefix = "${var.customer}-${var.environment}"
  tags = {
    CreatedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "${local.unique_prefix}-tfstate-bucket"

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags

}

resource "aws_s3_bucket_versioning" "terraform_state_bucket" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_public_access_block" {
  bucket                  = aws_s3_bucket.terraform_state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_lock_table" {
  name           = "${local.unique_prefix}-tfstate-lock-table"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags

}

resource "aws_s3_bucket_policy" "terraform_state_bucket" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "RequireEncryption",
   "Statement": [
    {
      "Sid": "RequireEncryptedTransport",
      "Effect": "Deny",
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.bucket}/*"],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Principal": "*"
    },
    {
      "Sid": "RequireEncryptedStorage",
      "Effect": "Deny",
      "Action": ["s3:PutObject"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.terraform_state_bucket.bucket}/*"],
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      },
      "Principal": "*"
    }
  ]
}
EOF
}

# Plan bucket

resource "aws_s3_bucket" "terraform_plan_bucket" {
  bucket = "${local.unique_prefix}-tfplan-bucket"

  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags

}

resource "aws_s3_bucket_versioning" "terraform_plan_bucket" {
  bucket = aws_s3_bucket.terraform_plan_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_plan_bucket" {
  bucket = aws_s3_bucket.terraform_plan_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfplan_s3_public_access_block" {
  bucket                  = aws_s3_bucket.terraform_plan_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "terraform_plan_bucket" {
  bucket = aws_s3_bucket.terraform_plan_bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "RequireEncryption",
  "Statement": [
    {
      "Sid": "RequireEncryptedTransport",
      "Effect": "Deny",
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.terraform_plan_bucket.bucket}/*"],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Principal": "*"
    },
    {
      "Sid": "RequireEncryptedStorage",
      "Effect": "Deny",
      "Action": ["s3:PutObject"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.terraform_plan_bucket.bucket}/*"],
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      },
      "Principal": "*"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "terraform_aws_oidc_github_cicd" {
  statement {
    sid       = "terraform"
    actions   = ["*"]
    resources = ["*"]
  }
}

module "github_oidc" {
  source = "../oidc-github"


  github_organization = "airtimemedia"
  github_repository_role = {
    "oidc_github" = {
      repository                  = "kafka-poc",
      iam_role_name               = "${local.unique_prefix}-oidc-github-cicd"
      iam_source_policy_documents = [data.aws_iam_policy_document.terraform_aws_oidc_github_cicd.json]
    }
  }
}