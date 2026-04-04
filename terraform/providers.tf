terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "LB-GlobexInfraOps"
    workspaces {
      name = "efesto-aws-dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  # region viene da var.aws_region; le credenziali arrivano come env vars
  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY impostate nel workspace HCP.
  # Il profile locale (lb-aws-admin) è usato solo in esecuzione locale.
  region  = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
