output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.single_lambda.arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}
