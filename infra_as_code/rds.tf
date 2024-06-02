# Randomizing a password for the rds database
resource "random_password" "db_password" {
  length           = 12
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Creating RDS instance with all necessary parameters
resource "aws_db_instance" "wordpressRDS" {
  identifier = "wordpressrds"
  max_allocated_storage = 20
  allocated_storage = 20
  storage_type = "gp2"
  db_name = "wordpressRDS"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"    
  username = "admin"
  password = random_password.db_password.result
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  multi_az = true
  db_subnet_group_name = aws_db_subnet_group.rdsSubnetGroup.name
  vpc_security_group_ids = [aws_security_group.rdsSG.id]
}

# Subnet group for RDS
resource "aws_db_subnet_group" "rdsSubnetGroup" {
  name = "mainsg"
  subnet_ids = [aws_subnet.DB-1A.id, aws_subnet.DB-1B.id]

  tags = {
    Name = "Subnet group for RDS DB"
  }
}