# Notes
This module creates all CodeDeploy resources including application-files


# Important Variables

```hcl
variable "codedeploy_apps" {
  description = "List of applications to deploy using CodeDeploy"
  type        = list(string)
  default     = []
}

variable "autoscaling_group_names" {
  description = "Map of Auto Scaling group names for each application"
  type        = map(string)
  default     = {}
}
```

- `codedeploy_apps`: Each application passed into the list will have all CodeDeploy Resources created for it
- `autoscaling_group_names`: Input the ASG's created in the EC2 module

```hcl
 #Pass in individual app names to create CodeDeploy resources for each
  codedeploy_apps = ["Beta"]

  #Create Code Deploy deployment group with individual autoscaling groups
  autoscaling_group_names = module.ec2[0].autoscaling_group_names
```