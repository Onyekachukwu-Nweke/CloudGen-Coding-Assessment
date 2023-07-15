# Create a Launch Template for EC2 AutoScaling Group
resource "aws_launch_template" "cloudgen-launch_temp" {
  name          = "cloudgen-launch_temp"
  image_id      = var.server_info.image_id
  instance_type = var.server_info.instance_type
  key_name      = var.server_info.key_name
  vpc_security_group_ids = [aws_security_group.cloudgen_alb_sg.id]

  block_device_mappings {
    device_name = var.server_info.device_name
    ebs {
      volume_size = var.server_info.volume_size
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.cloudgen_alb_sg.id]
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
resource "aws_autoscaling_group" "cloudgen-asg" {
  name            = "cloudgen-asg"
  desired_capacity = 2
  min_size = 2
  max_size = 4
  vpc_zone_identifier = [for subnet in aws_subnet.private_subnets : subnet.id]
  target_group_arns = [aws_alb_target_group.cloudgen-tg.arn]
  
  launch_template {
    id      = aws_launch_template.cloudgen-launch_temp.id
    version = "$Latest"
  }

   lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "Name"
    value               = "cloudgen-instance"
    propagate_at_launch = true
  }
}

# Creation of EC2 instance / Load balancer security group
resource "aws_security_group" "cloudgen_alb_sg" {
  name        = "cloudgen_alb_sg"
  description = "Allow TLS inbound traffic"

  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.inbound_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creates the AWS Application Load Balancer(ALB)
resource "aws_alb" "cloudgen-alb" {
  name               = "cloudgen-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cloudgen_alb_sg.id]
  subnets = aws_subnet.public_subnets.*.id
}

# Creates an ALB target group
resource "aws_alb_target_group" "cloudgen-tg" {
  name     = "AlbTargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    unhealthy_threshold = 2
  }

}

resource "aws_alb_listener" "new_listener" {
  load_balancer_arn = aws_alb.new_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.arn
  default_action {
    target_group_arn = aws_alb_target_group.cloudgen-tg.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "http_to_https" {
  load_balancer_arn = aws_alb.cloudgen-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.cloudgen-tg.arn
    type             = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

output "alb_dns_name" {
  value = aws_alb.cloudgen-alb.dns_name
}
