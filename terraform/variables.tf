variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "lb-aws-admin"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "threetier"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "taskdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "taskadmin"
}

variable "backend_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 3000
}

variable "backend_image" {
  description = "Full Docker image URI (set after pushing to ECR). Leave empty to use ECR repo URL with :latest tag."
  type        = string
  default     = ""
}

variable "backend_cpu" {
  description = "ECS task vCPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}
