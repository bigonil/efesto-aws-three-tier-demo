# ⏱️ Project Build Timeline — efesto-aws-three-tier-demo

> **Nota**: I tempi riportati sono stime basate sulla complessità di ciascun componente,
> non misurazioni precise di orologio. Il progetto è stato realizzato in un'unica sessione
> interattiva con GitHub Copilot CLI (modello: Claude Sonnet 4.6).

---

## Riepilogo Generale

| Metrica | Valore |
|---------|--------|
| **Tempo totale stimato** | ~45 minuti |
| **File creati** | 32 |
| **Righe di codice** | ~2.105 |
| **Moduli Terraform** | 5 (vpc, security-groups, database, backend, frontend) |
| **Sessione** | GitHub Copilot CLI — sessione singola |

---

## Dettaglio per Fase

| # | Fase | Componenti Creati | Tempo Stimato |
|---|------|-------------------|:-------------:|
| 1 | **Analisi requisiti & architettura** | Design three-tier, scelta stack (ECS Fargate, RDS, CloudFront, S3), pianificazione moduli Terraform | ~5 min |
| 2 | **Terraform root** | `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars.example` | ~4 min |
| 3 | **Modulo VPC** | VPC, subnet pubbliche/private/DB (2 AZ), IGW, 2 NAT GW, route tables | ~3 min |
| 4 | **Modulo Security Groups** | SG per ALB, ECS, RDS con regole ingress/egress minimali | ~2 min |
| 5 | **Modulo Database** | RDS PostgreSQL 15, Secrets Manager, random_password, subnet group | ~3 min |
| 6 | **Modulo Backend — infrastruttura** | ECR (+ lifecycle policy), ALB, target group, ECS cluster, task definition, ECS service | ~6 min |
| 7 | **Modulo Backend — IAM** | ECS Execution Role, ECS Task Role, policy per Secrets Manager | ~2 min |
| 8 | **Modulo Frontend** | S3 bucket (private), CloudFront OAC, distribuzione con dual-origin (S3 + ALB), bucket policy | ~4 min |
| 9 | **App Backend** | `package.json`, `Dockerfile`, `src/index.js` (Express REST API completa, schema auto-create, seed data) | ~5 min |
| 10 | **App Frontend** | `index.html`, `style.css`, `app.js` (SPA vanilla JS, CRUD completo) | ~3 min |
| 11 | **Script di deploy** | `build-and-push.ps1` (Docker → ECR → ECS), `deploy-frontend.ps1` (S3 sync → CloudFront invalidation) | ~3 min |
| 12 | **Documentazione** | `README.md` (guida completa), `migration-to-azure/README.md` (mapping AWS → Azure) | ~3 min |
| 13 | **`.gitignore`** | Terraform state, secrets, node_modules, OS files | ~1 min |
| 14 | **HCP Terraform backend** | Blocco `cloud` in `providers.tf`, token salvato in `credentials.tfrc.json` | ~1 min |
| 15 | **Rinomina cartella** | `aws-three-tier-demo` → `efesto-aws-three-tier-demo` | < 1 min |
| 16 | **Git init + commit + push** | `git init`, commit iniziale (32 file), creazione repo GitHub privato `bigonil/efesto-aws-three-tier-demo`, push | ~1 min |

---

## Distribuzione del Tempo per Area

```
Terraform (infrastruttura)  ████████████████░░░░  ~24 min  (53%)
Applicazione (backend+UI)   ████████░░░░░░░░░░░░  ~ 8 min  (18%)
Script & automazione        ██████░░░░░░░░░░░░░░  ~ 4 min  ( 9%)
Documentazione              ██████░░░░░░░░░░░░░░  ~ 4 min  ( 9%)
Setup & configurazione      ████░░░░░░░░░░░░░░░░  ~ 3 min  ( 7%)
Git & deploy                ██░░░░░░░░░░░░░░░░░░  ~ 2 min  ( 4%)
```

---

## Stack Tecnologico Utilizzato

| Layer | Tecnologia |
|-------|-----------|
| IaC | Terraform >= 1.5 (HCP backend) |
| Cloud | AWS (ECS Fargate, RDS PostgreSQL 15, S3, CloudFront, ALB, ECR, Secrets Manager) |
| Backend | Node.js 18 + Express 4 |
| Frontend | HTML5 / CSS3 / Vanilla JS |
| Container | Docker (node:18-alpine) |
| CI/CD scripts | PowerShell 7 |
| VCS | Git + GitHub (private repo) |

---

## Repository

🔗 [github.com/bigonil/efesto-aws-three-tier-demo](https://github.com/bigonil/efesto-aws-three-tier-demo)
