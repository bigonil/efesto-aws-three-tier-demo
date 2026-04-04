locals {
  prefix = "${var.project_name}-${var.environment}"
}

module "vpc" {
  source = "./modules/vpc"

  prefix             = local.prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security_groups" {
  source = "./modules/security-groups"

  prefix       = local.prefix
  vpc_id       = module.vpc.vpc_id
  backend_port = var.backend_port
}

module "database" {
  source = "./modules/database"

  prefix              = local.prefix
  db_subnet_group_ids = module.vpc.database_subnet_ids
  db_sg_id            = module.security_groups.rds_sg_id
  db_name             = var.db_name
  db_username         = var.db_username
}

module "backend" {
  source = "./modules/backend"

  prefix             = local.prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.security_groups.alb_sg_id
  ecs_sg_id          = module.security_groups.ecs_sg_id
  backend_port       = var.backend_port
  backend_cpu        = var.backend_cpu
  backend_memory     = var.backend_memory
  desired_count      = var.backend_desired_count
  backend_image      = var.backend_image
  db_secret_arn      = module.database.db_secret_arn
  db_host            = module.database.db_endpoint
  db_name            = var.db_name
  db_username        = var.db_username
  aws_region         = var.aws_region
}

module "frontend" {
  source = "./modules/frontend"

  prefix       = local.prefix
  alb_dns_name = module.backend.alb_dns_name
}
