# This describes the VPC properties our web application will be hosted in

resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

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

# Create an Elastic IP for NAT Gateway 1
resource "aws_eip" "eip1" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "web_app-eip1"
  }
}

# Create an Elastic IP for NAT Gateway 2
resource "aws_eip" "eip2" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "web_app-eip2"
  }
}

# Create NAT Gateway 1

resource "aws_nat_gateway" "nat-gatw1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.pub-sub1.id

  tags = {
    Name = "eks-nat1"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Create a NAT Gateway 2

resource "aws_nat_gateway" "nat-gatw2" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = aws_subnet.pub-sub2.id

  tags = {
    Name = "eks-nat2"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Creates a public subnet in each Availability Zone
resource "aws_subnet" "public_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}

# Creates a private subnet in each Availability Zone
resource "aws_subnet" "private_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index + 2)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
}

# Creates private route table for private subnet 1
resource "aws_route_table" "priv-rt-1" {
  vpc_id = aws_vpc.main.id
}

# Creates private route table for private subnet 2
resource "aws_route_table" "priv-rt-2" {
  vpc_id = aws_vpc.main.id
}

# Creates public route table for the public subnet 1 and 2
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.main.id
}

