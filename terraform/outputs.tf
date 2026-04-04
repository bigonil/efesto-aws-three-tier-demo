output "frontend_url" {
  description = "CloudFront URL (main entry point)"
  value       = "https://${module.frontend.cloudfront_domain}"
}

output "api_url" {
  description = "ALB URL for direct API access"
  value       = "http://${module.backend.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL — use this to push your Docker image"
  value       = module.backend.ecr_repository_url
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend assets"
  value       = module.frontend.s3_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation)"
  value       = module.frontend.cloudfront_distribution_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.backend.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.backend.ecs_service_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
