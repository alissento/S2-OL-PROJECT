provider "aws" {
  region = "eu-central-1"
}

# Creating a VPC for our whole infrastructure
resource "aws_vpc" "WordpressVPC" {
  cidr_block = "10.10.0.0/21"

  tags = {
    Name = "wordpressVPC"
  }
}

# Two web app subnets for our wordpress instances
resource "aws_subnet" "WEBAPP-1A" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "WEBAPP-1A"
  }
}

resource "aws_subnet" "WEBAPP-1B" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.4.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "WEBAPP-1B"
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

# Internet gateway for the wordpress servers 
resource "aws_internet_gateway" "wordpressIG" {
  vpc_id = aws_vpc.WordpressVPC.id
  tags = {
    Name = "wordpressIG"
  }
  
}

# Route table for wordpress servers to let them have connection to the internet
resource "aws_route_table" "webapp_routetable" {
  vpc_id = aws_vpc.WordpressVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpressIG.id
  }

  tags = {
    Name = "webappRouteTable"
  }
}

resource "aws_route_table_association" "webapp_routetable_association_webapp_a" {
  subnet_id = aws_subnet.WEBAPP-1A.id
  route_table_id = aws_route_table.webapp_routetable.id
}

resource "aws_route_table_association" "webapp_routetable_association_webapp_b" {
  subnet_id = aws_subnet.WEBAPP-1B.id
  route_table_id = aws_route_table.webapp_routetable.id
}

# Security group settings for wordpress servers
resource "aws_security_group" "webappSG" {
  name        = "webappSG"
  description = "Allow SSH and HTTP traffic for webserver"
  vpc_id      = aws_vpc.WordpressVPC.id

  tags = {
    Name = "webappSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.webappSG.id
  cidr_ipv4         = "3.120.181.40/29"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.webappSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.webappSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}