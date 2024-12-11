resource "aws_iam_role" "codedeploy_service_role" {
  name = "${local.unique_prefix}-CodeDeploy-ServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_policy" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSCodeDeployRole"
}

#S3 IAM Policy Document
data "aws_iam_policy_document" "s3_artifacts_iam_policy_doc" {
  statement {
    actions = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = [
      "${aws_s3_bucket.codedeploy_artifacts.arn}/*",
      "${aws_s3_bucket.codedeploy_artifacts.arn}"
    ]
  }
}

# S3 IAM Policy
resource "aws_iam_policy" "s3_artifacts_policy" {
  name   = "${local.unique_prefix}-s3-artifacts-policy"
  policy = data.aws_iam_policy_document.s3_artifacts_iam_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "codedeploy_s3_artifacts" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = aws_iam_policy.s3_artifacts_policy.arn
}
