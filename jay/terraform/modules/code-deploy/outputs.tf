output "autoscaling_group_names" {
  value = var.autoscaling_group_names
}

output "app_names" {
  value = { for k, v in aws_codedeploy_deployment_group.app_deployment_group : k => v.app_name }
}

output "app_deployment_group_names" {
  value = { for k, v in aws_codedeploy_deployment_group.app_deployment_group : k => v.deployment_group_name }
}