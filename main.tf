terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>4.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_instance" "nginx" {
    ami = "ami-0b86b6d499bcd4261"
    instance_type = "t2.micro"
    user_data = file("nginx.sh")
    tags = { 
    Name  = "NGINX"
  }
}

resource "aws_instance" "apache" {
    ami = "ami-0b86b6d499bcd4261"
    instance_type = "t2.micro"
    user_data = file("apache.sh")
    tags = { 
        Name  = "APACHE"
    }
}
