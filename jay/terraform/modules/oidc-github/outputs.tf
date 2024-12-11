output "iam_role_arn" {
  depends_on  = [aws_iam_role.github_role]
  description = "ARN of the IAM roles created"
  value       = [for v in aws_iam_role.github_role : v.arn]
}

output "oidc_provider_arn" {
  depends_on  = [aws_iam_openid_connect_provider.github_provider]
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github_provider.arn
}
