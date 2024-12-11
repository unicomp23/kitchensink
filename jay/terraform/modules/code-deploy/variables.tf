variable "codedeploy_apps" {
  description = "List of applications to deploy using CodeDeploy"
  type        = list(string)
  default     = []
}

variable "env" {
  type        = string
  description = "Environment"
  default     = ""
}

variable "customer" {
  type        = string
  description = "Customer"
  default     = "cantina"

}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted when deleting the bucket"
  type        = bool
  default     = true
}

variable "object_lock_mode" {
  description = "The default object Lock retention mode to apply to new objects"
  type        = string
  default     = null
}

variable "autoscaling_group_names" {
  description = "Map of Auto Scaling group names for each application"
  type        = map(string)
  default     = {}
}

variable "app_asg_name" {
  type    = string
  default = ""
}

variable "beta_asg_name" {
  type    = string
  default = ""
}

variable "cron_asg_name" {
  type    = string
  default = ""
}

variable "proxy_asg_name" {
  type    = string
  default = ""
}
