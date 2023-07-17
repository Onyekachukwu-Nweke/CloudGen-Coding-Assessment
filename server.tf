# Create a Launch Template for EC2 AutoScaling Group
resource "aws_launch_template" "cloudgen-launch_temp" {
  name          = "cloudgen-launch_temp"
  image_id      = var.server_info.image_id
  instance_type = var.server_info.instance_type
  # key_name      = var.server_info.key_name
  vpc_security_group_ids = [aws_security_group.cloudgen_alb_sg.id]

  block_device_mappings {
    device_name = var.server_info.device_name
    ebs {
      volume_size = var.server_info.volume_size
    }
  }

  # User Data is used to provision our web app on the servers
  user_data = base64encode(templatefile("userdata.tfpl", { rds_endpoint = "${aws_db_instance.db_server.endpoint}", user  = var.database_user , password = var.database_password , dbname = var.database_name }))
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

  depends_on = [aws_security_group.cloudgen_alb_sg]

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

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.cloudgen-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.cloudgen-tg.arn}"
    type             = "forward"
  }
}

# Creation of RDS security group
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "RDS security group"

  vpc_id = aws_vpc.main.id

  ingress {
    description = "ssh"
    security_groups= [aws_security_group.cloudgen_alb_sg.id]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.private_subnets : subnet.cidr_block]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups= [aws_security_group.cloudgen_alb_sg.id]
    cidr_blocks = [for subnet in aws_subnet.private_subnets : subnet.cidr_block]
  }
}

# Creates a DB Subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [for subnet in aws_subnet.private_subnets : subnet.id]
}

# Creates a RDS instance
resource "aws_db_instance" "db_server" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7.42"
  instance_class       = "db.t2.micro"
  db_name              = var.database_name
  username             = var.database_user
  password             = var.database_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  multi_az             = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot = true

  tags = {
    Name = "CloudGen-RDS-MYSQL"
  }
}
