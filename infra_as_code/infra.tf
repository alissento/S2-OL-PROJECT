provider "aws" {
  region = "eu-central-1"
}

# Creating a VPC for our whole infrastructure
resource "aws_vpc" "WordpressVPC" {
  cidr_block = "10.10.0.0/21"

  tags = {
    Name = "WordpressVPC"
  }
}

# Two web app subnets for our wordpress instances testest
resource "aws_subnet" "WEBAPP-1A" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "WEBAPP-1A"
  }
}

resource "aws_subnet" "WEBAPP-1B" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.4.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "WEBAPP-1A"
  }
}

# Two subnets for EFS service
resource "aws_subnet" "EFS-1A" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "EFS-1A"
  }
}

resource "aws_subnet" "EFS-1B" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.5.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "EFS-1B"
  }
}

# Two subnets for RDS
resource "aws_subnet" "DB-1A" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "DB-1A"
  }
}

resource "aws_subnet" "DB-1B" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.6.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "DB-1B"
  }
}