resource "random_password" "db" {
  length  = 20
  special = false
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.prefix}/db/password"
  description             = "RDS PostgreSQL master password for ${var.prefix}"
  recovery_window_in_days = 0 # immediate delete for demo

  tags = { Name = "${var.prefix}-db-secret" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.prefix}-db-subnet-group"
  subnet_ids = var.db_subnet_group_ids

  tags = { Name = "${var.prefix}-db-subnet-group" }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.prefix}-postgres"
  engine         = "postgres"
  engine_version = "17.9"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]

  publicly_accessible     = false
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = { Name = "${var.prefix}-postgres" }

  depends_on = [aws_secretsmanager_secret_version.db]
}
