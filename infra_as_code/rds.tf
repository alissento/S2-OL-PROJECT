# TODO Create a simpel for now rds database just to see how it is working with terraform

# resource "aws_db_instance" "wordpressRDS" {
#   allocated_storage    = 10
#   db_name              = "wordpressRDS"
#   engine               = "mysql"
#   engine_version       = "8.0"
#   instance_class       = "db.t3.micro"
#   username             = "admin"
#   password             = "admin"
#   parameter_group_name = "default.mysql8.0"
#   skip_final_snapshot  = true
# }