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

## Prerequisites
Before I began the Project, I had the following:

1. An AWS account with appropriate permissions to create and manage resources.
2. AWS CLI installed and configured with your AWS credentials.
3. Terraform installed on your local machine.


## Assumptions
Based on the provided requirements, here are some technical assumptions that can be made for the project:

1. **AWS Account**: It is assumed that you have a valid AWS account and the necessary credentials to access and manage AWS resources.

2. **AMI Image**: The Amazon Machine Image (AMI) ID for the EC2 instances is assumed to be available. You need to provide the appropriate AMI ID in the Terraform configuration for launching the instances.

3. **Key Pair**: A key pair is assumed to exist for SSH access to the EC2 instances. You need to have the private key file or its corresponding key pair name.

4. **SSL Certificate**: There is no SSL certificate yet for the project.

5. **Route 53 and ACM**: There is no domain name yet for the application.

6. **Database**: The choice of MySQL as the database engine for the RDS instance is assumed based on the provided Terraform configuration.

7. **Cost Considerations**: The provided Terraform script sets up infrastructure that may incur costs, such as EC2 instances, load balancer, and RDS instances. Cost optimization and monitoring are assumed to be the responsibility of the user.


## Infrastructure Overview of our Web Application

The architecture we are going to set up consists of the following components:

1. __VPC Internet Gateway:__ AWS Internet Gateway lets a resource in your public subnets that has a public IPv4 or IPv6 address connect to the Internet. Resources on the internet can link to resources in your subnet using the accessible IPv4 or IPv6 address.

2. __Load Balancer:__ An Elastic Load Balancer (ELB) that distributes incoming traffic across multiple EC2 instances.

3. __Elastic IP Address:__ An Elastic IP address is a static IPv4 address designed for dynamic cloud computing. An Elastic IP address is a public IPv4 address, which is reachable from the internet. If your instance does not have a public IPv4 address, you can associate an Elastic IP address with your instance to enable communication with the internet.

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

11. `userdata.tfpl` file is a user data script that will be used to configure the launch template that the Auto Scaling Group will use.


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
```
