# AWS Scalable and Secure Web Application using Terraform

This README provides a step-by-step guide on how to use Terraform to set up an AWS environment with an auto-scaling EC2 setup behind a load balancer and an RDS instance with High Availability, ensuring secure communication between them.

<b>*_Objective:_*</b>

We're planning to launch a new web application. You are to create a
Terraform script that sets up an AWS environment with an auto-scaling EC2 setup
behind a load balancer, and an RDS instance, ensuring secure communication
between them.

<b>*_Deliverable:_*</b>

Provide the Terraform scripts and a README file that explains the
architecture and instructions to execute the scripts.

## Table of Contents

- [AWS Scalable and Secure Web Application using Terraform](#aws-scalable-and-secure-web-application-using-terraform)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Assumptions](#assumptions)
  - [Infrastructure Overview of our Web Application](#infrastructure-overview-of-our-web-application)
  - [Terraform Setup](#terraform-setup)
  - [Terraform Configuration](#terraform-configuration)
  - [Deploying the Infrastructure](#deploying-the-infrastructure)
  - [Cleanup](#cleanup)
  - [Challenges Faced and Solutions on the Project](#challenges-faced-and-solutions-on-the-project)
  - [Technical Trade-offs](#technical-trade-offs)
  - [References](#references)


## Prerequisites
Before I began the Project, I had the following:

1. An AWS account with appropriate permissions to create and manage resources.
2. AWS CLI installed and configured with your AWS credentials.
3. Terraform installed on your local machine.


## Assumptions
Based on the provided requirements, here are some technical assumptions that Imade for the project:

1. **AWS Account**: It is assumed that you have a valid AWS account and the necessary credentials to access and manage AWS resources.

2. **AMI Image**: The Amazon Machine Image (AMI) ID for the EC2 instances is assumed to be available. You need to provide the appropriate AMI ID in the Terraform configuration for launching the instances.

3. **Key Pair**: A key pair is assumed not to exist for SSH access to the EC2 instances. It can only be connected through the console for security reasons.

4. **SSL Certificate**: There is no SSL certificate yet for the project.

5. **Route 53 and ACM**: There is no domain name yet for the application.

6. **Database**: The choice of MySQL as the database engine for the RDS instance is assumed based on the provided Terraform configuration.

7. **Cost Considerations**: The provided Terraform script sets up infrastructure that may incur costs, such as EC2 instances, load balancer, elastic ip, nat gateways and RDS instances. Cost optimization and monitoring are assumed to be the responsibility of the user.


## Infrastructure Overview of our Web Application

The architecture we are going to set up consists of the following components:

1. __VPC Internet Gateway:__ AWS Internet Gateway lets a resource in your public subnets that has a public IP address connect to the Internet. Resources on the internet can link to resources in your subnet using the accessible IP address.

2. __Load Balancer:__ An Elastic Load Balancer (ELB) that distributes incoming traffic across multiple EC2 instances in different subnets.

3. __Elastic IP Address:__ An Elastic IP address is used to connect to NAT gateways due to instability and enable them to connect to the internet in this infrastructure.

4. __AWS NAT Gateway:__ NAT Gateway is used to connect instances securely in the private subnet to the internet.

5. __Auto Scaling Group:__ A group of EC2 instances that automatically scales based on traffic load and health status.

6. __EC2 Instances:__ The web application servers that will host your web application.

7. __RDS Instance:__ A highly available Relational Database Service (RDS) instance for storing application data securely and enabling its data replication feature.

8. __Route Tables:__ Route Tables to control where traffic is directed.

9. __Public Subnet:__ Public Subnet is for connecting the resources in the private subnet to the internet securely.

10. __Private Subnet:__ Private Subent is where the sensitive resources like the web app server(EC2) and database servers(RDS mysql) to prevent security breach so they are not directly connected to the internet.

11. __Multi-AZ Deployment:__ I made use of two availability zones to avoid single point of failure for smooth running of our web app, should there be a disaster in one of the AZs.

12. __Security Groups:__ A security group controls the traffic that is allowed to reach and leave the resources that it is associated with.

Here is a diagram illustrating the architecture:

![Infrastructural Diagram](/img/architectural_diagram.png)


## Terraform Setup

1. Created a new directory on my local machine for Terraform configuration.
```
mkdir CloudGen-Coding-Assessment
cd CloudGen-Coding-Assessment
```

2. Initialized a new Terraform project by running the following command:
```
terraform init
```

3. Created the provider terraform file (`provider.tf`) in the project directory. This file will contain
provider specifications of the project.

4. Created a network terraform file (`network.tf`) which contains all AWS network resources
and configurations of the project.

5. Created a variables file (`variables.tf`) to define any input variables needed in the infrastructure setup.

6. Create an output file (`outputs.tf`) to define any outputs you want to display after the infrastructure deployment.

7. Create a server terraform file (`server.tf`) in the project directory. This file will contain the AWS web server(ec2) and database(rds) resource definitions and their configurations.

8. Create a secret terraform file (`secret.tfvars`) in the project directory. This file holds sensitive data and is not normally committed to a public repository.

9. `nginx` file contains a modified version of nginx configuration that will serve the application

10. `index.php` file contains the web application we are provisioning for the project.

11. `userdata.tfpl` template file is a user data script that will be used to configure the launch template that the Auto Scaling Group will use.


## Terraform Configuration

Deep dive into the Terraform configuration files and define our AWS infrastructure.

1. __Configure the Provider__

In the `provider.tf` file, configure the AWS provider using your AWS credentials.

```
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = var.aws_region
}
```

2. __Creation of VPC__

Define a VPC resource in my `network.tf` file

```
resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}
```

**Evidence of VPC creation**
![vpc creation](/img/vpc.png)

3. __Creation of Internet Gateway and attachment to VPC__

Defines an Internet Gateway resource and attach it to the specified VPC.

```
# Creates an internet gateway to route traffic from the internet
resource "aws_internet_gateway" "internet_gw" {
  tags = {
    Name = var.internet_gw
  }
}

# Internet Gateway Attachment
resource "aws_internet_gateway_attachment" "igw-attach" {
  internet_gateway_id = aws_internet_gateway.internet_gw.id
  vpc_id              = aws_vpc.main.id
}
```

**Evidence of Internet Gateway Creation**
![igw creation](/img/igw.png)

4. __Creation of Elastic IP Addresses__

Defines the Elastic IP that are situated in the public subnet, that will be used by
NAT gateways due to its unstable nature (ie it can reset at anytime).

```
# Create an Elastic IP for NAT Gateway 1
resource "aws_eip" "eip1" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gw]
  tags = {
    Name = "cloudgen-eip1"
  }
}

# Create an Elastic IP for NAT Gateway 2
resource "aws_eip" "eip2" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gw]
  tags = {
    Name = "cloudgen-eip2"
  }
}
```

**Evidence of Elastic IP creation**
![eip](/img/eip.png)

5. __Creation of Both Public and Private Subnets__

Defines the creation of Public and Private subnet in each availability zone

```
# Creates a public subnet in each Availability Zone
resource "aws_subnet" "public_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "cloudgen-pub_sub-${count.index + 1}"
  }
}

# Creates a private subnet in each Availability Zone
resource "aws_subnet" "private_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    "Name" = "cloudgen-priv_sub-${count.index + 1}"
  }
}
```

**Evidence of Creation of Subnets**
![subnets](/img/subnets.png)

6. __Creation of NAT Gateways__

Defines the NAT Gateway resources that will be connected to the
private subnets for internet connectivity.

```
# Create NAT Gateway 1
resource "aws_nat_gateway" "nat-gatw1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, 0)

  tags = {
    Name = "cloudgen-nat1"
  }
  depends_on = [aws_internet_gateway.internet_gw]
}

# Create a NAT Gateway 2
resource "aws_nat_gateway" "nat-gatw2" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, 1)

  tags = {
    Name = "cloudgen-nat2"
  }
  depends_on = [aws_internet_gateway.internet_gw]
}
```

**Evidence of Creation of NAT Gateways**
![nat gateway](/img/nat.png)

7. __Creation of Route Table and Association of Route Tables__

Defines the creation of Route tables resources and association of these route tables
to their appropriate subnets.

```
# Create Route Table for public sub 1 and 2
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "cloudgen-pub-rt"
  }
}

# Create Route Table for private sub 1
resource "aws_route_table" "priv-rt1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gatw1.id
  }

  tags = {
    Name = "cloudgen-priv-rt1"
  }
}

# Create Route Table for private sub 2
resource "aws_route_table" "priv-rt2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gatw2.id
  }

  tags = {
    Name = "cloudgen-priv-rt2"
  }
}

# Associate public subnet 1 with public route table 1
resource "aws_route_table_association" "pub-sub1-association" {
  subnet_id      = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.pub-rt.id
}

# Associate public subnet 2 with public route table 1
resource "aws_route_table_association" "pub-sub2-association" {
  subnet_id      = aws_subnet.public_subnets[1].id
  route_table_id = aws_route_table.pub-rt.id
}


# Associate private subnet 1 with private route table 1
resource "aws_route_table_association" "priv-sub1-association" {
  subnet_id      = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.priv-rt1.id
}

# Associate private subnet 2 with private route table 2
resource "aws_route_table_association" "priv-sub2-association" {
  subnet_id      = aws_subnet.private_subnets[1].id
  route_table_id = aws_route_table.priv-rt2.id
}
```

**Evidence of Route Table Creation**
![rtb](/img/route.png)

8. __Creation of Launch Template__

Defines the EC2 instance configurations and informations concerning the servers
like storage capacity, type of storage, security group and user data. User data
is a startup script that runs upon the creation of EC2 instance using that particular
launch template.

```
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
```

**Evidence of Launch Template Creation**
![Lt](/img/launch-temp.png)

9. __Creation of Auto Scaling Group__

Defines the creation auto scaling group which creates an EC2 instance in each private subnet specified.

```
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
```

**Evidence of Auto Scaling Group and EC2 Creation**
![asg](/img/asg.png)
![ec2](/img/ec2.png)

10. __Creation of EC2 and RDS Security Group__

Defines the ec2 security group which will be attached to the ec2 instances that are created by the autoscaling group and also the RDS security group that allows access to the EC2 instances to write to the RDS server
```
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
```

**Evidence of Security Group Creation**
![sg](/img/sg.png)

11. __Creation of Load Balancer and Target Groups__

Defines the creation of Application internet facing load balancer that route traffic to the servers in a balanced way, but Load balancers cannot do this without having a target group which contains a list of servers/instances that traffic can be routed to and also the listeners which port they are send and pick up traffic from.

```
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
```

**Evidence of Creation of Loadbalancer and Target Groups**
![lb](/img/lb.png)
![lb-tg](/img/lb-tg.png)
![lb-targets](/img/lb-targets.png)

12. __Creation of DB Subnet Group__

Defines a DB Subnet Group resource that allows the RDS instance to be placed in multiple availability zones.

```
# Creates a DB Subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [for subnet in aws_subnet.private_subnets : subnet.id]
}
```

13. __Creation Of RDS Server__

Defines an RDS instance resource that will serve as the highly available database for the project.

```
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
```

**Evidence of RDS creation**
![rds](/img/rds_act.png)

14. __Outputs__

Displays useful information about some infrastructure deployed, they are contained in the `outputs.tf` file.

```
output "rds_endpoint" {
  value = aws_db_instance.db_server.endpoint
}

output "alb_dns_name" {
  value = aws_alb.cloudgen-alb.dns_name
}
```

## Deploying the Infrastructure

1. After setting up the Terraform configuration files, run the following command to validate your configuration.

```
terraform validate
```
Make sure there are no errors.

2. Run the Terraform plan command to see the execution plan without making any changes.

```
terraform plan -var-file=secret.tfvars
```
The `secret.tfvars` file should contain aws access key and aws secret key
Review the output to ensure all the resources and configurations are as expected.

3. If the plan looks correct, apply the Terraform changes to create the infrastructure.

```
terraform apply -var-file=secret.tfvars
```
Confirm the action by typing "yes" when prompted.

4. Terraform will now create the AWS resources defined in your configuration files. This process may take several minutes.

5. Once the deployment is complete, you can access your web application using the load balancer DNS name.

## Cleanup

To destroy the created AWS resources and clean up your environment, run the following command:
```
terraform destroy -var-file=secret.tfvars
```
Confirm the action by typing "yes" when prompted.

## Challenges Faced and Solutions on the Project

Here are some challenges I faced when building this infrastructure:

1. **Infrastructure Complexity:** Setting up an auto-scaling EC2 setup with a load balancer, combined with a highly available RDS instance, can introduce complexity in terms of configuration, networking, and coordination between different components.

  **Solution**

  I made use of Lucid Charts for Diagramming to produce an infrastructure diagram that served as a guide for me while building the infrastructure of the project.

2. **Networking and Security Considerations:** Ensuring secure communication between the EC2 instances and the RDS instance requires proper networking configurations, security groups, and encryption protocols. Handling network connectivity, firewall rules, and secure data transfer can be complex, and misconfigurations can lead to communication failures or security vulnerabilities.

  **Solution**

  I made use of route tables to correctly route traffic to the appropriate subnets and there respective security groups.

3. **Cost Optimization:** Achieving the desired scalability and high availability can come with additional costs, such as increased EC2 instances, load balancer usage, elastic ip, nat gateways and RDS instance replication. Balancing performance and redundancy requirements with cost efficiency and optimizing resource allocation can be a challenge, especially when dealing with fluctuating application traffic.

  **Solution**

  I tried to optimize for cost by choosing lower instance type and also checking for high-availability, and avoiding single point of failure in the infrastructure.

4. **Integration and Application Compatibility:** Ensuring that the web application is compatible with the auto-scaling setup, load balancer, and RDS instance, including any required database modifications or application configurations.

  **Solution**

  To solve this challenge I had to explicitly specify the version of php and rds (mysql) version I needed.

## Technical Trade-offs

Here are some technical trade-offs, I considered when building this infrastructure:

1. **Scalability vs. Cost:** Implementing an auto-scaling EC2 setup behind a load balancer allows for improved scalability and handling of increased traffic. However, scaling infrastructure can come with additional costs, especially if the application experiences frequent spikes in usage. It's crucial to strike a balance between scalability requirements and cost constraints.

2. **High Availability vs. Complexity:** Setting up an RDS instance with high availability ensures better resilience against failures. However, achieving high availability often involves more complex configurations, such as multi-AZ deployments and failover mechanisms. Balancing the desired level of availability with the complexity of setup and maintenance is important.

3. **Secure Communication vs. Performance:** Ensuring secure communication between the EC2 instances and the RDS instance adds an extra layer of security. However, implementing encryption and secure communication protocols can introduce additional processing overhead, potentially impacting overall system performance. Finding the right balance between security and performance is crucial.

4. **Infrastructure as Code (IaC) vs. Development Speed:** Using Terraform for infrastructure provisioning and configuration brings benefits like reproducibility, version control, and automation. However, adopting IaC practices may require additional time and effort to set up and maintain infrastructure code. Evaluating the trade-off between development speed and the long-term benefits of IaC is necessary.

5. **Vendor Lock-in vs. Flexibility:** Leveraging AWS services offers scalability and managed solutions. However, relying heavily on AWS services may result in vendor lock-in, limiting the ability to switch to alternative cloud providers in the future. Balancing the advantages of using AWS services with the desire for flexibility and avoiding excessive vendor dependencies is important.

6. **Complexity vs. Maintenance:** The use of advanced AWS services, such as auto-scaling, load balancers, and RDS with high availability, can introduce increased complexity in terms of configuration and maintenance. Assessing the trade-off between the complexity of the chosen architecture and the team's ability to effectively manage and maintain it is crucial.

**Evidence Of Deployed Web App**
![web app](/img/webapp.png)

## References

Here are some helpful references for further reading:

- [AWS Account Sign-Up](https://aws.amazon.com/free/): Sign up for an AWS account if you don't have one.

- [Getting Started with Terraform](https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started): Guide to installing and setting up Terraform for your first project.

- [Creating an IAM User in AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html): AWS documentation on how to create an IAM user in your AWS account.

- [AWS RDS Provisioning](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html): AWS documentation on provisioning RDS resources.

- [Terraform AWS Instance Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance): Documentation for the Terraform AWS instance resource, which allows you to create EC2 instances.

- [Installing and Configuring AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html): AWS documentation on installing and configuring the AWS CLI for managing your AWS resources.

- [AWS Security Groups](https://registry.terraform.io/providers/hashicorp/aws/3.11.0/docs/resources/security_group): Documentation for the Terraform AWS security group.