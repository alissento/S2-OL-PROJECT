output "region_name" {
  value = var.target_region
  description = "Region name"
}

output "first_availability_zone" {
  value = local.region_availability_zones[0]
  description = "First availability zone"
}
output "second_availability_zone" {
  value = local.region_availability_zones[1]
  description = "Second availability zone"
}

output "vpc_cidr" {
  value = aws_vpc.WordpressVPC.cidr_block
  description = "IP range of whole infrastructure"
}

output "rds_username" {
  value = aws_db_instance.wordpressRDS.username
  description = "Database username"
}

output "rds_password" {
  value = aws_db_instance.wordpressRDS.password
  sensitive = true
  description = "Database password"
}

output "lb_dns" {
  value = aws_lb.wordpressLoadBalancer.dns_name
  description = "Loadbalancer dns name. Used for accessing wordpress in the browser"
}

output "EC2_AMI" {
  value = data.aws_ami.amazon_linux_2023.id
  description = "AMI that ec2 instances are using as thier operating system"
}