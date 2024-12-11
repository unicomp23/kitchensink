resource "aws_codedeploy_app" "app" {
  for_each = toset(var.codedeploy_apps)

  name             = "${each.value}-codedeploy-app"
  compute_platform = "Server"

  tags = {
    Name = "${each.value}-codedeploy-app"
  }
}

# Deployment Group for Application
resource "aws_codedeploy_deployment_group" "app_deployment_group" {
  for_each = { for app in var.codedeploy_apps : app => var.autoscaling_group_names[app] if contains(keys(var.autoscaling_group_names), app) }

  app_name              = aws_codedeploy_app.app[each.key].name
  deployment_group_name = "${each.key}-app-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  autoscaling_groups = [each.value]

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
