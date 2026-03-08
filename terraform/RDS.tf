resource "aws_db_subnet_group" "db_group" {
  name       = "${var.project_name}-db-group"
  subnet_ids = [aws_subnet.db_pri_1a.id, aws_subnet.db_pri_1c.id]
}

resource "aws_db_instance" "main" {
  allocated_storage      = 10
  db_name                = "${var.project_name}_db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_group.name
  multi_az               = false
}