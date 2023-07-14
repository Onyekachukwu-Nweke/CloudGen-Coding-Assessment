# This describes the VPC properties our web application will be hosted in

resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

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

