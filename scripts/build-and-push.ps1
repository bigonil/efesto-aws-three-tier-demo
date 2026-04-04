<#
.SYNOPSIS
  Build the backend Docker image and push it to ECR.
  Run this AFTER terraform apply has created the ECR repository.

.USAGE
  cd aws-three-tier-demo
  .\scripts\build-and-push.ps1
#>

param(
  [string]$Profile = "lb-aws-admin",
  [string]$Region  = "eu-west-1",
  [string]$Tag     = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Step 1: Get ECR repository URL from Terraform ===" -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\terraform"
try {
  $TF_OUTPUT = terraform output -json | ConvertFrom-Json
  $ECR_URL   = $TF_OUTPUT.ecr_repository_url.value
  $CLUSTER   = $TF_OUTPUT.ecs_cluster_name.value
  $SERVICE   = $TF_OUTPUT.ecs_service_name.value
} finally {
  Pop-Location
}

if (-not $ECR_URL) {
  Write-Error "ecr_repository_url not found in terraform output. Run 'terraform apply' first."
}

Write-Host "ECR Repository: $ECR_URL" -ForegroundColor Green

Write-Host "`n=== Step 2: Docker login to ECR ===" -ForegroundColor Cyan
$ACCOUNT_ID = ($ECR_URL -split "\.")[0]
$ECR_HOST   = "$ACCOUNT_ID.dkr.ecr.$Region.amazonaws.com"

aws ecr get-login-password --region $Region --profile $Profile |
  docker login --username AWS --password-stdin $ECR_HOST

Write-Host "`n=== Step 3: Build Docker image ===" -ForegroundColor Cyan
$IMAGE_TAG = "${ECR_URL}:${Tag}"
docker build -t $IMAGE_TAG "$PSScriptRoot\..\app\backend"

Write-Host "`n=== Step 4: Push image to ECR ===" -ForegroundColor Cyan
docker push $IMAGE_TAG
Write-Host "Pushed: $IMAGE_TAG" -ForegroundColor Green

Write-Host "`n=== Step 5: Force ECS service redeployment ===" -ForegroundColor Cyan
aws ecs update-service `
  --cluster  $CLUSTER `
  --service  $SERVICE `
  --force-new-deployment `
  --region   $Region `
  --profile  $Profile | Out-Null

Write-Host "`nWaiting for service to stabilize (this may take 2-3 minutes)..." -ForegroundColor Yellow
aws ecs wait services-stable `
  --cluster $CLUSTER `
  --services $SERVICE `
  --region  $Region `
  --profile $Profile

Write-Host "`n✅ Backend deployed successfully!" -ForegroundColor Green
Write-Host "   Image: $IMAGE_TAG"
