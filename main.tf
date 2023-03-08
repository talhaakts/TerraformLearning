terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

locals {
  user_data = <<EOF
    #cloud-config
    runcmd:
    - sudo apt update -y
    - sudo apt install docker.io -y
    - sudo apt install vim -y
    - sudo docker run --name talha -p 80:80 -d nginx 
    - sudo docker exec -i -t talha echo  helloworld >> /usr/share/nginx/html/index.html  

  EOF
}

resource "aws_key_pair" "oguz_key" {
  key_name   = "oguz-key"
  public_key = "${file("/root/.ssh/id_rsa.pub")}"
}

resource "aws_instance" "oguz_server" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.medium"
  key_name      = "${aws_key_pair.oguz_key.key_name}"
  user_data = "${local.user_data}"
  vpc_security_group_ids = ["${aws_security_group.allow_http.id}"]
  tags = {
    Name = "Oguz-Terraform"
  }
}


resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTPD inbound traffic"
  vpc_id      = "vpc-060bea2dcb7c23f0f"

  ingress {
    description      = "HTTPD from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_httpd"
  }
}
