terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change this to your desired AWS region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc"
  }
}

# Create two public subnets for NAT gateways
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "public_subnet_2"
  }
}

# Create two private subnets for EC2 instances
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "private_subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "private_subnet_2"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}

# Create a route table for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate public route table with public subnets
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create NAT gateways in public subnets
#resource "aws_nat_gateway" "nat_gateway_1" {
#resource "aws_nat_gateway" "natgateway_1" {
#  allocation_id = aws_eip.eip.id
#  allocation_id = aws_subnet.public_subnet_1.id
#  subnet_id     = aws_subnet.private_subnet_1.id
#}
#resource "aws_nat_gateway" "nat_gateway_2" {
#resource "aws_nat_gateway" "natgateway_2" {
#  allocation_id = aws_eip.eip.id
#  allocation_id = aws_subnet.public_subnet_2.id
#  subnet_id     = aws_subnet.private_subnet_2.id
#}

# Create a route table for private subnets
resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.my_vpc.id
}

# Associate private route table with private subnets
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}

# Create two EC2 instances in public subnets
resource "aws_instance" "ec2_instance_1" {
  ami           = "ami-0b86b6d499bcd4261"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name      = "devopstest"  # Replace with your key pair name
  associate_public_ip_address = true
  

  tags = {
    Name = "EC2_Instance_1"
  }
}

resource "aws_instance" "ec2_instance_2" {
  ami           = "ami-0b86b6d499bcd4261"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_2.id
  key_name      = "devopstest"  # Replace with your key pair name
  associate_public_ip_address = true

  tags = {
    Name = "EC2_Instance_2"
  }
}
# Create security group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.my_vpc.id

  // Add any necessary inbound rules for ALB
}

# Create ALB
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection       = false
  enable_http2                     = true
  idle_timeout                     = 60
  enable_cross_zone_load_balancing = true

}

# Register EC2 instances with the ALB
resource "aws_lb_target_group" "my_target_group" {
  name        = "my-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "instance"

  health_check {
    path     = "/"
    protocol = "HTTP"
    port     = 80
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:us-east-1:129882018060:loadbalancer/app/my-alb/dfd3d9c15d384599"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }
}
