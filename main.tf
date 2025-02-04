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
resource "aws_subnet" "public-sm" {
  vpc_id     = aws_vpc.test.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

#private subnet
resource "aws_subnet" "private-sm" {
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
  subnet_id = aws_subnet.public-sm
  tags = {
    Name = "Public-Ec2"
  }
}

#private ec2
resource "aws_instance" "private_ec2" {
  ami                     = "ami-0c614dee691cbbf37"
  instance_type           = "t2.micro"
  subnet_id = aws_subnet.private-sm
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