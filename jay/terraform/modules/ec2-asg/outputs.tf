output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.ec2_lt.id
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling group"
  value       = aws_autoscaling_group.ec2_asg.name
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.sg.id
}
