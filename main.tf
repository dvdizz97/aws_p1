# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Main-VPC"
  }
}

#public subnet
resource "aws_subnet" "public_sm" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

#private subnet
resource "aws_subnet" "private_sm" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "Private-subnet"
  }
}

#public Ec2
resource "aws_instance" "bastion_ec2" {
  ami                     = "ami-0c614dee691cbbf37"
  instance_type           = "t2.micro"
  subnet_id = aws_subnet.public_sm.id
  tags = {
    Name = "Public-Ec2"
  }
}

#private ec2
resource "aws_instance" "private_ec2" {
  ami                     = "ami-0c614dee691cbbf37"
  instance_type           = "t2.micro"
  subnet_id = aws_subnet.private_sm.id
  tags = {
    Name = "private-Ec2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test.id

  tags = {
    Name = "igw"
  }
}

# Create a Route Table for the Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test.id

  # Add a Route to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0" # Default route to the internet
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the Public Subnet with the Route Table
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_sm.id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_sm.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "elastic_ip" {
  domain = "vpc"
}

# Route Table for the Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.test.id

  # Route for internet traffic via NAT Gateway
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate the Private Subnet with the Route Table
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_sm.id
  route_table_id = aws_route_table.private.id
}

# Security Group for Private EC2 Instance
resource "aws_security_group" "private_ec2_sg" {
  vpc_id = aws_vpc.test.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Allow traffic only from within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic
  }

  tags = {
    Name = "private-ec2-sg"
  }
}

