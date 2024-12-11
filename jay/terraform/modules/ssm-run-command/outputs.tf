output "ssm_document_name" {
  description = "Name of the created SSM document"
  value       = aws_ssm_document.command_document.name
}

output "ssm_association_id" {
  description = "ID of the SSM association"
  value       = aws_ssm_association.command_association.id
}
