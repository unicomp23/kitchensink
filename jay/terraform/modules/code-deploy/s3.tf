resource "aws_s3_bucket" "codedeploy_artifacts" {
  bucket              = "${local.unique_prefix}-cd-artifacts"
  force_destroy       = var.force_destroy
  object_lock_enabled = var.object_lock_mode != null ? true : false

  tags = {
    Name = "${local.unique_prefix}-cd-artifacts"
  }
}

# resource "aws_s3_object" "app_artifact_appspec" {
#   for_each = toset(var.codedeploy_apps)

#   bucket = aws_s3_bucket.codedeploy_artifacts.id
#   key    = "${each.key}/appspec.yml"
#   source = "${path.module}/codedeploy_artifacts/${each.key}/appspec.yml"
#   etag   = filemd5("${path.module}/codedeploy_artifacts/${each.key}/appspec.yml")
# }

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  rule {
    id = "log"

    expiration {
      days = 90
    }

    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Policy Document
data "aws_iam_policy_document" "s3_artifacts_bucket_policy_doc" {
  statement {
    actions = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = [
      "${aws_s3_bucket.codedeploy_artifacts.arn}/*",
      "${aws_s3_bucket.codedeploy_artifacts.arn}"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.codedeploy_service_role.name}"]
    }
  }
}

resource "aws_s3_bucket_policy" "codedeploy_artifacts_policy" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id
  policy = data.aws_iam_policy_document.s3_artifacts_bucket_policy_doc.json
}