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
  depends_on = [aws_internet_gateway.internet_gw]
  tags = {
    Name = "web_app-eip1"
  }
}

# Create an Elastic IP for NAT Gateway 2
resource "aws_eip" "eip2" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gw]
  tags = {
    Name = "web_app-eip2"
  }
}

# Creates a public subnet in each Availability Zone
resource "aws_subnet" "public_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
}

# Creates a private subnet in each Availability Zone
resource "aws_subnet" "private_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
}

# Create NAT Gateway 1
resource "aws_nat_gateway" "nat-gatw1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, 0)

  tags = {
    Name = "web_app-nat1"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Create a NAT Gateway 2
resource "aws_nat_gateway" "nat-gatw2" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, 1)

  tags = {
    Name = "web_app-nat2"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Create Route Table for public sub 1 and 2
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "web_app-pub-rt"
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
    Name = "web_app-priv-rt1"
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
    Name = "web_app-priv-rt2"
  }
}

# Associate public subnet 2 with public route table
resource "aws_route_table_association" "pub-sub2-association" {
  subnet_id      = aws_subnet.pub-sub2.id
  route_table_id = aws_route_table.pub-rt.id
}

# Associate private subnet 1 with private route table 1
resource "aws_route_table_association" "priv-sub1-association" {
  subnet_id      = aws_subnet.priv-sub1.id
  route_table_id = aws_route_table.priv-rt1.id
}

# Associate private subnet 2 with private route table 2
resource "aws_route_table_association" "priv-sub2-association" {
  subnet_id      = aws_subnet.priv-sub2.id
  route_table_id = aws_route_table.priv-rt2.id
}

