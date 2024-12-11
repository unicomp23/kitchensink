output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state_bucket.id
}

output "dynamo_db_table_name" {
  value = aws_dynamodb_table.terraform_state_lock_table.id
}
