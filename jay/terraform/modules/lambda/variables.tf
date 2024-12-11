variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "memory_size" {
  description = "Amount of memory to allocate to the Lambda function (MB)"
  type        = number
  default     = 4096 # 4 GB
}

variable "timeout" {
  description = "Lambda function timeout (seconds)"
  type        = number
  default     = 900 # 15 minutes
}

variable "ephemeral_storage_size" {
  description = "Amount of ephemeral storage to allocate (MB)"
  type        = number
  default     = 2048 # 2 GB
}

variable "pandas_layer_arn" {
  description = "ARN of the Lambda layer with pandas and numpy"
  type        = string
}