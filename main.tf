terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_newvpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_newvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
# Create a public subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_newvpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
# Create an Internet Gateway 1
resource "aws_internet_gateway" "my_internet_gateway_1" {
  vpc_id = aws_vpc.my_newvpc.id
}
# Create an Internet Gateway 2
resource "aws_internet_gateway" "my_internet_gateway_2" {
  vpc_id = aws_vpc.my_newvpc.id
}
# Create a route table for the public subnet 1
resource "aws_route_table" "public_route_table_1" {
  vpc_id = aws_vpc.my_newvpc.id
}

# Associate the public subnet with the public route table 1
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table_1.id
}
# Create a route table for the public subnet 2
resource "aws_route_table" "public_route_table_2" {
  vpc_id = aws_vpc.my_newvpc.id
}

# Associate the public subnet with the public route table 2
resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table_2.id
}
# Create a route in the public route table 1 to the Internet through the Internet Gateway
resource "aws_route" "internet_route_1" {
  route_table_id         = aws_route_table.public_route_table_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_internet_gateway_1.id
}
# Create a route in the public route table 2 to the Internet through the Internet Gateway
resource "aws_route" "internet_route_2" {
  route_table_id         = aws_route_table.public_route_table_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_internet_gateway_2.id
}
# Create a security group allowing inbound SSH traffic
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.my_newvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in the public subnet 1
resource "aws_instance" "my_instance_1" {
  ami           = "ami-0b86b6d499bcd4261"  # Replace with the actual AMI ID
  instance_type = "t2.micro"      # Choose the desired instance type
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name      = "devopstest" # Replace with the name of your EC2 key pair
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "MyEC2-sub1"
  }
}
# Create an EC2 instance in the public subnet 2
resource "aws_instance" "my_instance_2" {
  ami           = "ami-0b86b6d499bcd4261"  # Replace with the actual AMI ID
  instance_type = "t2.micro"      # Choose the desired instance type
  subnet_id     = aws_subnet.public_subnet_2.id
  key_name      = "devopstest" # Replace with the name of your EC2 key pair
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "MyEC2-sub2"
  }
}
