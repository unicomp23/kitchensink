resource "aws_iam_role" "app_role" {

  name = "${local.unique_prefix}-${var.name_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

########################################################################
# AWS Managed Policies 
########################################################################
resource "aws_iam_role_policy_attachment" "aws_managed_policy_Msk_full_access" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonMSKFullAccess"
  role       = aws_iam_role.app_role.name
}

resource "aws_iam_role_policy_attachment" "aws_managed_policy_S3_full_access" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.app_role.name
}

resource "aws_iam_role_policy_attachment" "aws_managed_policy_Codedeploy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
  role       = aws_iam_role.app_role.name
}

resource "aws_iam_role_policy_attachment" "aws_managed_policy_CodedeployReadOnly" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSCodeDeployReadOnlyAccess"
  role       = aws_iam_role.app_role.name
}

resource "aws_iam_role_policy_attachment" "aws_managed_policy_ElastiCacheReadOnly" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonElastiCacheReadOnlyAccess"
  role       = aws_iam_role.app_role.name
}

resource "aws_iam_role_policy_attachment" "aws_managed_policy_AmazonSSMFullAccess" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMFullAccess"
  role       = aws_iam_role.app_role.name

}

########################################################################
# Inline Policies
########################################################################
resource "aws_iam_role_policy" "secrets_read_only_policy" {
  name = "SecretsReadOnly"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "ASG-${local.unique_prefix}-${var.name_prefix}-instance-profile"
  role = aws_iam_role.app_role.name
}
