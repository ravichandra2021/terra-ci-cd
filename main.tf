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
  gateway_id             = aws_internet_gateway.my_internet_gateway_1.id
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
# Create security group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.my_newvpc.id

  // Add any necessary inbound rules for ALB
 ingress {
    from_port   = 80  // HTTP traffic
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic from any source
  }

  ingress {
    from_port   = 443  // HTTPS traffic
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Allow traffic from any source
  }

  // Add any other necessary inbound rules here

  // Outbound rules (allow all outbound traffic by default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
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
  vpc_id      = aws_vpc.my_newvpc.id
  target_type = "instance"

  health_check {
    path     = "/"
    protocol = "HTTP"
    port     = 80
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:us-east-1:129882018060:loadbalancer/app/my-alb/f9fcf9fc13e4ff39"
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

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
