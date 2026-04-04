# AWS → Azure Three-Tier Migration Guide

This document maps each AWS component of the three-tier demo to its Azure equivalent,
with notes on configuration differences.

## Architecture Mapping

| Layer | AWS (Source) | Azure (Target) | Notes |
|-------|-------------|----------------|-------|
| **CDN + Static Hosting** | S3 + CloudFront | Azure Static Web Apps OR Azure Blob Storage + Azure CDN | Static Web Apps is the closest 1:1 (includes CDN, CI/CD built-in) |
| **Container Orchestration** | ECS Fargate | Azure Container Apps | Serverless containers, same model. Scale to zero supported on both. |
| **Load Balancer** | Application Load Balancer (ALB) | Azure Application Gateway OR Azure Load Balancer | For HTTP/HTTPS routing, Application Gateway is the equivalent |
| **Database** | RDS PostgreSQL | Azure Database for PostgreSQL – Flexible Server | Near-identical managed PostgreSQL service |
| **Container Registry** | ECR | Azure Container Registry (ACR) | Same concept. ACR supports geo-replication. |
| **Secrets Management** | AWS Secrets Manager | Azure Key Vault (Secrets) | Key Vault also manages keys and certificates |
| **Networking** | VPC | Azure Virtual Network (VNet) | |
| **Subnets** | Public/Private Subnets | Azure Subnets | VNet integration required for Container Apps private subnet |
| **Firewall Rules** | Security Groups | Azure Network Security Groups (NSG) | NSGs attach to subnets or NICs; SGs attach to resources |
| **IAM Roles** | IAM Roles + Instance Profiles | Azure Managed Identity + RBAC | Managed Identity is the preferred approach in Azure |
| **Monitoring/Logs** | CloudWatch Logs | Azure Monitor + Log Analytics Workspace | |
| **Infrastructure as Code** | Terraform (AWS provider) | Terraform (AzureRM provider) | Same Terraform workflow, different provider/resources |

---

## Migration Steps (High Level)

### Phase 1 — Azure Infrastructure (Terraform)
1. Create a new Terraform project (`terraform-azure/`)
2. Define AzureRM provider and authentication (Service Principal or AZ CLI)
3. Provision:
   - Resource Group
   - Virtual Network + Subnets
   - Azure Container Registry (replace ECR)
   - Azure Database for PostgreSQL Flexible Server (replace RDS)
   - Azure Key Vault + Secret for DB password (replace Secrets Manager)
   - Azure Container Apps Environment + App (replace ECS Fargate + ALB)
   - Azure Blob Storage (static website) + Azure CDN (replace S3 + CloudFront)

### Phase 2 — Application Changes
The Node.js backend requires **zero code changes** — it uses standard environment variables.

Only the container **registry URL** changes:
```bash
# AWS ECR
docker tag backend:latest <account>.dkr.ecr.eu-west-1.amazonaws.com/threetier-demo-backend:latest

# Azure ACR
docker tag backend:latest <registry>.azurecr.io/threetier-demo-backend:latest
az acr login --name <registry>
docker push <registry>.azurecr.io/threetier-demo-backend:latest
```

### Phase 3 — Container Apps Environment Variables
Replace the ECS task definition environment with Azure Container Apps configuration:

| ECS Task Env Var | Azure Container Apps Secret/Env | Source |
|---|---|---|
| `DB_HOST` | Env var | Azure PostgreSQL FQDN |
| `DB_NAME` | Env var | same value |
| `DB_USERNAME` | Env var | same value |
| `DB_PASSWORD` | Secret ref → Key Vault | Azure Key Vault secret |
| `PORT` | Env var | same value (3000) |

### Phase 4 — DNS & Traffic Cutover
1. Update DNS CNAME from CloudFront domain → Azure CDN endpoint
2. Verify health checks pass
3. Decommission AWS resources

---

## Key Differences to Note

| Topic | AWS | Azure |
|-------|-----|-------|
| **Pricing model** | Per-request (Secrets Manager $0.05/10k calls) | Key Vault requests free up to 10k/month |
| **Fargate vs Container Apps** | ECS Fargate: explicit CPU/memory allocation | Container Apps: consumption-based auto-scaling |
| **PostgreSQL** | RDS: parameter groups for tuning | Flexible Server: server parameters via portal/CLI |
| **VNet integration** | ECS tasks in private subnets natively | Container Apps require VNet injection (Consumption Dedicated plan) |
| **CloudFront vs CDN** | 400+ PoPs globally | Azure CDN (Akamai/Verizon): similar coverage |
| **IAM vs RBAC** | Policy documents (JSON) | Role Assignments + Built-in roles |

---

## Terraform Module Comparison

```
AWS (source)                          Azure (target)
──────────────────────────────────── ─────────────────────────────────────
modules/vpc/                          modules/vnet/
  aws_vpc                               azurerm_virtual_network
  aws_subnet                            azurerm_subnet
  aws_nat_gateway                       azurerm_nat_gateway
  aws_internet_gateway                  (built into VNet)

modules/security-groups/              modules/nsg/
  aws_security_group                    azurerm_network_security_group
                                        azurerm_subnet_network_security_group_association

modules/database/                     modules/database/
  aws_db_instance (postgres)            azurerm_postgresql_flexible_server
  aws_secretsmanager_secret             azurerm_key_vault_secret

modules/backend/                      modules/backend/
  aws_ecr_repository                    azurerm_container_registry
  aws_ecs_cluster                       azurerm_container_app_environment
  aws_ecs_task_definition               azurerm_container_app
  aws_lb                                azurerm_container_app (ingress built-in)

modules/frontend/                     modules/frontend/
  aws_s3_bucket                         azurerm_storage_account (static website)
  aws_cloudfront_distribution           azurerm_cdn_profile + azurerm_cdn_endpoint
```
