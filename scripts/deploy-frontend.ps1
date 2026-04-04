<#
.SYNOPSIS
  Upload frontend static assets to S3 and invalidate CloudFront cache.
  Run this AFTER terraform apply has created the S3 bucket and CloudFront distribution.

.USAGE
  cd aws-three-tier-demo
  .\scripts\deploy-frontend.ps1
#>

param(
  [string]$Profile = "lb-aws-admin",
  [string]$Region  = "eu-west-1"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Step 1: Get S3 and CloudFront details from Terraform ===" -ForegroundColor Cyan
Push-Location "$PSScriptRoot\..\terraform"
try {
  $TF_OUTPUT        = terraform output -json | ConvertFrom-Json
  $S3_BUCKET        = $TF_OUTPUT.s3_bucket_name.value
  $CF_DISTRIBUTION  = $TF_OUTPUT.cloudfront_distribution_id.value
  $FRONTEND_URL     = $TF_OUTPUT.frontend_url.value
} finally {
  Pop-Location
}

Write-Host "S3 Bucket:    $S3_BUCKET" -ForegroundColor Green
Write-Host "CloudFront ID: $CF_DISTRIBUTION" -ForegroundColor Green

Write-Host "`n=== Step 2: Upload frontend assets to S3 ===" -ForegroundColor Cyan
$FRONTEND_DIR = "$PSScriptRoot\..\app\frontend"

aws s3 sync $FRONTEND_DIR "s3://$S3_BUCKET" `
  --delete `
  --cache-control "max-age=3600" `
  --exclude "*.ps1" `
  --profile $Profile `
  --region  $Region

# HTML should not be cached aggressively (so updates are seen immediately)
aws s3 cp "$FRONTEND_DIR\index.html" "s3://$S3_BUCKET/index.html" `
  --cache-control "no-cache, no-store, must-revalidate" `
  --content-type "text/html" `
  --profile $Profile `
  --region  $Region

Write-Host "`n=== Step 3: Invalidate CloudFront cache ===" -ForegroundColor Cyan
aws cloudfront create-invalidation `
  --distribution-id $CF_DISTRIBUTION `
  --paths "/*" `
  --profile $Profile | Out-Null

Write-Host "`n✅ Frontend deployed successfully!" -ForegroundColor Green
Write-Host "   URL: $FRONTEND_URL"
Write-Host "   (CloudFront propagation may take 1-2 minutes)"
