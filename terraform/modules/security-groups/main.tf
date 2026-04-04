# ── ALB Security Group (internet-facing) ──────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb-sg"
  description = "ALB: allow HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.prefix}-alb-sg" }
}

# ── ECS Security Group (private) ──────────────────────────────────────────────
resource "aws_security_group" "ecs" {
  name        = "${var.prefix}-ecs-sg"
  description = "ECS Fargate: accept traffic only from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "App port from ALB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound: ECR pull, Secrets Manager, RDS"
  }

  tags = { Name = "${var.prefix}-ecs-sg" }
}

# ── RDS Security Group (isolated) ─────────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.prefix}-rds-sg"
  description = "RDS PostgreSQL: accept connections only from ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
    description     = "PostgreSQL from ECS only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.prefix}-rds-sg" }
}
