# Notes
This is the only time we will be running terraform commands locally.
Here we are setting following necessary resources that we need to run to make terraform setup.

## Steps
1. Set local `terminal` with AWS credentials.
2. Open `terraform/modules/00-remote-state-aws-backend`
4. Run following terraform commands:
```
terraform init
terraform plan
terraform apply
```
## Info
- This is the only time we are running terraform commands manually to setup tf state resources.
- Please store the remote state file in github remotely(`terraform.tfstate`). Keep in mind this is the only case storing state file remotely.
