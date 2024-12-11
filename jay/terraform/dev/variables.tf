variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "environment" {
  description = "The name of the environment to deploy resources"
  type        = string
}

variable "customer" {
  type        = string
  description = "The customer name."
}

variable "kafka_broker_instance_type" {
  description = "Instance type for Kafka brokers"
  type        = string
  default     = "kafka.m7g.xlarge"
}

variable "number_of_brokers" {
  description = "Number of Kafka brokers"
  type        = number
  default     = 3
}

variable "producer_instance_type" {
  description = "Instance type for Kafka producers"
  type        = string
  default     = "c5.large"
}

variable "producer_desired_capacity" {
  description = "Desired capacity for Kafka producers"
  type        = number
  default     = 1
}

variable "producer_max_size" {
  description = "Max size for Kafka producers"
  type        = number
  default     = 1
}

variable "producer_min_size" {
  description = "Min size for Kafka producers"
  type        = number
  default     = 1
}

variable "consumer_instance_type" {
  description = "Instance type for Kafka consumers"
  type        = string
  default     = "c5.4xlarge"
}

variable "consumer_desired_capacity" {
  description = "Desired capacity for Kafka consumers"
  type        = number
  default     = 1
}

variable "consumer_max_size" {
  description = "Max size for Kafka consumers"
  type        = number
  default     = 1
}

variable "consumer_min_size" {
  description = "Min size for Kafka consumers"
  type        = number
  default     = 1
}