variable "target_region" {
  description = "Type a desired AWS region to deploy this project"
  type = string

  validation {
    condition = contains(["us-east-1", "us-east-2", "us-west-1", "us-west-2", "ca-central-1", "sa-east-1", "eu-central-1", "eu-west-1", "eu-west-2", "eu-west-3", "eu-north-1", "eu-north-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-south-1"], var.target_region)
    error_message = "Invalid region. Allowed regions are: us-east-1, us-east-2, us-west-1, us-west-2, ca-central-1, sa-east-1, eu-central-1, eu-west-1, eu-west-2, eu-west-3, eu-north-1, ap-southeast-1, ap-southeast-2, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-south-1."
  }
}

data "aws_availability_zones" "azs" {
  state = "available"

  filter {
    name   = "region-name"
    values = [var.target_region]
  }
}

locals {
  region_availability_zones = slice(data.aws_availability_zones.azs.names, 0, 2)
}

provider "aws" {
  region = var.target_region
}

# Creating a VPC for our whole infrastructure
resource "aws_vpc" "WordpressVPC" {
  cidr_block = "10.10.0.0/21"
  enable_dns_hostnames = true
  tags = {
    Name = "wordpressVPC"
  }
}

# Two web app subnets for our wordpress instances
resource "aws_subnet" "WEBAPP-1A" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.0.0/24"
  availability_zone = local.region_availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "WEBAPP-1A"
  }
}

resource "aws_subnet" "WEBAPP-1B" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.4.0/24"
  availability_zone = local.region_availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "WEBAPP-1B"
  }
}

# Two subnets for EFS service
resource "aws_subnet" "EFS-1A" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.1.0/24"
  availability_zone = local.region_availability_zones[0]

  tags = {
    Name = "EFS-1A"
  }
}

resource "aws_subnet" "EFS-1B" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.5.0/24"
  availability_zone = local.region_availability_zones[1]

  tags = {
    Name = "EFS-1B"
  }
}

# Two subnets for RDS
resource "aws_subnet" "DB-1A" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.2.0/24"
  availability_zone = local.region_availability_zones[0]

  tags = {
    Name = "DB-1A"
  }
}

resource "aws_subnet" "DB-1B" {
  vpc_id = aws_vpc.WordpressVPC.id
  cidr_block = "10.10.6.0/24"
  availability_zone = local.region_availability_zones[1]

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
  name = "webappSG"
  description = "Allow SSH and HTTP traffic for webserver"
  vpc_id = aws_vpc.WordpressVPC.id

  tags = {
    Name = "webappSG"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.webappSG.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_wordpress" {
  security_group_id = aws_security_group.webappSG.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Security group settings for RDS databases
resource "aws_security_group" "rdsSG" {
  name = "rdsSG"
  description = "Allow connection to rds dbs"
  vpc_id = aws_vpc.WordpressVPC.id

  tags = {
    Name = "rdsSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_db_port" {
  security_group_id = aws_security_group.rdsSG.id
  cidr_ipv4 = aws_vpc.WordpressVPC.cidr_block
  from_port = 3306
  ip_protocol = "tcp"
  to_port = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_rds" {
  security_group_id = aws_security_group.rdsSG.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Security group settings for EFS storage
resource "aws_security_group" "efsSG" {
  name = "efsSG"
  description = "Allow connection to efs"
  vpc_id = aws_vpc.WordpressVPC.id

  tags = {
    Name = "efsSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_nfs_port" {
  security_group_id = aws_security_group.efsSG.id
  cidr_ipv4 = aws_vpc.WordpressVPC.cidr_block
  from_port = 2049
  ip_protocol = "tcp"
  to_port = 2049
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_efs" {
  security_group_id = aws_security_group.efsSG.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

# Security group settings for application load balancer
resource "aws_security_group" "albSG" {
  name = "albSG"
  description = "Allow connection to alb"
  vpc_id = aws_vpc.WordpressVPC.id

  tags = {
    Name = "albSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_port_alb" {
  security_group_id = aws_security_group.albSG.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_alb" {
  security_group_id = aws_security_group.albSG.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}