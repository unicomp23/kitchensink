variable "document_name" {
  description = "Name of the SSM document"
  type        = string
}

variable "document_type" {
  description = "Type of SSM document"
  type        = string
  default     = "Command"
}

variable "commands" {
  description = "List of commands to run"
  type        = list(string)
}

variable "target_tag_key" {
  description = "Tag key to target instances"
  type        = string
  default     = "Name"
}

variable "target_tag_values" {
  description = "Tag values to target instances"
  type        = list(string)
}

# variable "schedule_expression" {
#   description = "Schedule for running the command"
#   type        = string
#   default     = "rate(1 day)"
# }
