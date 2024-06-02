output "region_name" {
  value = var.target_region
}

output "first_availability_zone" {
  value = local.region_availability_zones[0]
}
output "second_availability_zone" {
  value = local.region_availability_zones[1]
}

output "vpc_cidr" {
  value = aws_vpc.WordpressVPC.cidr_block
}

output "rds_username" {
  value = aws_db_instance.wordpressRDS.username
}

output "rds_password" {
  value = aws_db_instance.wordpressRDS.password
  sensitive = true
}