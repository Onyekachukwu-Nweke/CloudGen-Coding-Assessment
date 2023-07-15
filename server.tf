# Create a Launch Template for EC2 AutoScaling Group
resource "aws_launch_template" "cloudgen-launch_temp" {
  name          = "cloudgen-launch_temp"
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

  # User Data is used to provision our web app on the servers
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install -y --no-install-recommends php8.1
                sudo apt-get install -y php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-fpm
                sudo systemctl reload php8.1-fpm
                git clone https://github.com/Onyekachukwu-Nweke/server_stats_template.git
                sudo apt install -y nginx
                sudo mv server_stats_template/assets /var/www/html/
                sudo mv server_stats_template/index.php /var/www/html/
                git clone https://github.com/Onyekachukwu-Nweke/Alt-School-Sem3-Holiday-Project.git
                sudo cat Alt-School-Sem3-Holiday-Project/nginx | sudo tee /etc/nginx/sites-available/default
                sudo mv /var/www/html/index.nginx-debian.html ../
                sudo systemctl reload php8.1-fpm
                sudo systemctl restart nginx
                EOF

  tags = {
    Name = "cloudgen-launch_temp"
  }
}

# Creates an AutoScaling Group that will use the launch template
