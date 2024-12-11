# SSM Document
resource "aws_ssm_document" "command_document" {
  name            = var.document_name
  document_type   = var.document_type
  document_format = "YAML"

  content = templatefile("${path.module}/ssm_document_template.tftpl", {
    commands = var.commands
  })
}

# SSM Run Command Association
resource "aws_ssm_association" "command_association" {
  name = aws_ssm_document.command_document.name

  targets {
    key    = "tag:${var.target_tag_key}"
    values = var.target_tag_values
  }

  # schedule_expression = var.schedule_expression
}
