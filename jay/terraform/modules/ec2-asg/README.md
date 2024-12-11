# EC2 Auto Scaling Group Module

This module manages the EC2 Auto Scaling Group (ASG) configuration.

## Overview

- Manages EC2 instances using Auto Scaling.
- Ensures high availability and scalability.

## Inputs

- `ami_id`: The AMI ID for the instances.
- `instance_type`: The type of EC2 instances.
- `desired_capacity`: The desired number of instances.

## Outputs

- `autoscaling_group_name`: The name of the Auto Scaling Group.
- `launch_template_id`: The IDs of the Launch Template.

## Usage

The `ec2-asg` module is called from the root 'dev` directory. Refer to the root [README.md](../../README.md) for more details.

## License

This project is licensed under the MIT License.
