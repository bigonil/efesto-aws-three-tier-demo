output "db_endpoint" {
  # Strip port from endpoint (RDS returns host:port)
  value = split(":", aws_db_instance.main.endpoint)[0]
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "db_instance_id" {
  value = aws_db_instance.main.id
}
