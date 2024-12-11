variable "env" {
  description = "The environment for the resources"
  type        = string
}

variable "customer" {
  description = "The customer name for the resources"
  type        = string

}
variable "name_prefix" {
  description = "The prefix to use for all resources"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "ebs_volume_size" {
  description = "The size of the EBS volume in GB"
  type        = number
  default     = 8
}

variable "desired_capacity" {
  description = "The desired capacity of the Auto Scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum size of the Auto Scaling group"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "The minimum size of the Auto Scaling group"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The list of Subnets ID"
  type        = list(string)

}