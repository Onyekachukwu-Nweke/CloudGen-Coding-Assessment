# Create a Launch Template for EC2 AutoScaling Group
resource "aws_launch_template" "cloudgen-launch_temp" {
  name          = "ec2-launch_temp"
  image_id      = var.server_info.image_id
  instance_type = var.server_info.instance_type
  key_name      = var.server_info.key_name
  # vpc_security_group_ids = [aws_security_group.altschool_sg.id, aws_security_group.elb-sg.id]

  block_device_mappings {
    device_name = var.server_info.device_name
    ebs {
      volume_size = var.server_info.volume_size
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    # security_groups = [aws_security_group.ec2_security_group.id]
  }

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup python -m SimpleHTTPServer 80 &
                EOF

  tags = {
    Name = "cloudgen-launch_temp"
  }
}

