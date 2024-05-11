# TODO Create a simpel for now rds database just to see how it is working with terraform

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
  password = "adminadmin"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.rdsSubnetGroup.name
  vpc_security_group_ids = [aws_security_group.rdsSG.id]
}

resource "aws_db_subnet_group" "rdsSubnetGroup" {
  name = "mainsg"
  subnet_ids = [aws_subnet.DB-1A.id, aws_subnet.DB-1B.id]

  tags = {
    Name = "Subnet group for RDS DB"
  }
}