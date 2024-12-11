resource "aws_launch_template" "ec2_lt" {
  name_prefix   = "${var.name_prefix}-launchtemplate"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    security_groups = [aws_security_group.sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.ebs_volume_size
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-instance"
    }
  }

  # Importing user-data script from an external file in this directory
  user_data = base64encode(file("${path.module}/userdata.sh"))
}
