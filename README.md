# 🚀 AWS Multi-Region Disaster Recovery Platform (Terraform)


[![Deploy Multi-Region Infrastructure](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/deploy.yml/badge.svg)](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/deploy.yml)

[![Destroy Multi-Region Infrastructure](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/destroy.yml/badge.svg)](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/destroy.yml)


This project provisions a production-style WordPress infrastructure on AWS with multi-region disaster recovery (DR) using Terraform.

It demonstrates:

  * High availability (ALB + ECS)
  * Cross-region failover (Route53 + RDS replica)
  * Automated recovery (Step Functions + Lambda)
  * CDN acceleration (CloudFront)
  * Infrastructure as Code (Terraform)

---
# 📘 Table of Contents

- [What This Project Demonstrates](#what-this-project-demonstrates)
- [Architecture Overview](#architecture-overview)
- [Traffic Routing](#traffic-routing)
- [Demo Videos](#demo-videos)
- [Key Features](#key-features)
- [Engineering Decisions](#engineering-decisions)
- [Design Principles](#design-principles)
- [Technology Stack](#technology-stack)
- [Infrastructure Components](#infrastructure-components)
- [Failover Strategy](#failover-strategy)
- [Failure Scenarios & Recovery](#failure-scenarios--recovery)
- [Terraform Structure](#terraform-structure)
- [CI/CD Strategy](#cicd-strategy)
- [Reviewer Setup (How to Deploy This Project in Your AWS Account)](#reviewer-setup-how-to-deploy-this-project-in-your-aws-account)
- [CloudWatch Monitoring and Alarms](#cloudwatch-monitoring-and-alarms)
- [Security Best Practices Used](#security-best-practices-used)
- [Cost Optimization](#cost-optimization)
- [Known Limitations and Trade-offs](#known-limitations-and-trade-offs)
- [License](#license)

---

# **What This Project Demonstrates**

This project demonstrates:

  - Designing multi-region disaster recovery architectures
  - Making trade-offs between cost, complexity, and reliability
  - Implementing secure CI/CD with OIDC
  - Building production-ready infrastructure using Terraform
  - Understanding ure scenarios and controlled recovery strategies

---

# **Architecture Overview**

This project deploys a multi-region, production-grade WordPress platform using:

## Primary Region (us-east-1)
  * ECS (WordPress containers)
  * ALB (application traffic)
  * RDS MySQL (primary database)
  * S3 (media storage)
## DR Region (ca-central-1)
  * ECS (standby service)
  * ALB (failover target)
  * RDS Read Replica (promotable)
  * S3 (replicated)
## Global
  * Route53 (DNS + failover)
  * CloudFront (serves main domain)
  * Step Functions (DR orchestration)
  * Lambda (automation)

--- 

## Multi-Region Architecture (ASCII Diagram)

```text
                                   ┌──────────────┐
                                   │   Route 53   │
                                   └───────┬──────┘
                                           │
                            ┌──────────────▼────────────────┐
                            │      CloudFront (Global)      │
                            │  Origin Groups (Auto over)│
                            └───────────┬───────────┬───────┘
                                        │           │
                                      App         Media
                                 (Dynamic)      (Uploads)
                                        │           │
                 ┌─────────────────────▼────┐ ┌─────▼─────────────────────┐
                 │   ALB Primary (us-east-1)│ │  S3 Primary (us-east-1)   │
                 └───────────┬──────────────┘ └──────────────┬────────────┘
                             │                               │
                        ECS Tasks (Active)               Media Writes
                    Scale: 2 Tasks (Example)            Replication to DR
                             │                               │
                             │                               │
                 ┌───────────▼──────────────┐ ┌──────────────▼────────────┐
                 │   ALB DR (ca-central-1)  │ │   S3 DR (ca-central-1)    │
                 └───────────┬──────────────┘ └───────────────────────────┘
                             │
                        ECS Tasks (Standby)
                      Scale: 0 Tasks (Normal)

           Database Layer
           ┌───────────────────────────┐
           │   RDS Primary (Writer)    │
           │        us-east-1          │
           └────────────┬──────────────┘
                        │
                 Replication (Async)
                        ▼
           ┌───────────────────────────┐
           │  RDS Read Replica (DR)    │
           │      ca-central-1         │
           └───────────────────────────┘
                          
```

---

# **Traffic Routing**

Public Traffic

```text
rqays.com / www.rqays.com
        ↓
   CloudFront
        ↓
   ALB (Primary → DR failover)
```

Admin Traffic (WordPress Dashboard)
```text
admin.rqays.com
        ↓
Route53 Failover
        ↓
Primary ALB → DR ALB
```

Admin is routed directly to ALB (NOT CloudFront) because:

  * WordPress admin requires POST requests
  * CloudFront origin groups do not support POST
  * Ensures reliable login and writes

---

# **Demo Videos**

The following short demos walk through the full lifecycle of the project — from bootstrap and deployment to validation and disaster recovery simulation.

### ▶️ **Demo 1 (8 min)**  
**AWS Multi-Region WordPress DR – Bootstrap &  CI/CD Deployment (Terraform + OIDC)**  
https://youtu.be/-jRgfdVbeQc

Covers:
- Bootstrap IAM stack (OIDC, no static credentials)
- GitHub Actions → AWS authentication
- Automated multi-region Terraform deployment

---

### ▶️ **Demo 2 (4 min)**  
**AWS Multi-Region WordPress DR – Primary Region Validation**  
https://youtu.be/llBW524p_mY

Covers:
- WordPress frontend & admin access
- ALB + CloudFront behavior
- S3 media uploads
- RDS primary connectivity

---

### ▶️ **Demo 3 (10 min)**  
**AWS Multi-Region WordPress DR – Failover Simulation**  
https://youtu.be/taxhBePimCA

Covers:
- Primary region failure simulation
- CloudFront origin failover
- DR ALB traffic serving
- RDS replica promotion
- ECS scale-up in DR region
- S3 media uploads (in DR region)

*For operational procedures, see DR-RUNBOOK.md

---

> ℹ️ **Post-Demo Improvement Note**
>
> The demo videos were recorded before a final security enhancement was applied.
>
> At the time of recording, the WordPress admin interface (`admin.example.com/wp-admin`)
> triggered a browser SSL warning because the ACM certificate covered only the root domain.
>
> **After recording the demos**, the certificate configuration was improved to cover:
>
> ```
> *.example.com
> ```
>
> This eliminates all SSL warnings and ensures secure HTTPS access for both:
> - Frontend traffic
> - WordPress admin access
>
> The current code in this repository reflects the **improved and correct behavior**.

---

> 🔐 **Security Note**  
> All demos were recorded using a sandbox AWS account with GitHub Actions OIDC authentication.  
> No static AWS credentials, secrets, or IAM users were used or exposed.  
> All IAM roles, infrastructure, and credentials used during recording were destroyed immediately after the demos.

---

# **Key Features**

### 🟢 High Availability & Automated Failover

* Multi-region ECS + ALB
* Cross-region database replication
* CloudFront origin failover avoids DNS record changes and reduces DNS-related failover delay

### 🌍 Global Content Delivery

* S3 + CloudFront for media
* Uploads served from nearest edge location

### 🔒 Hardened Security

* TLS everywhere
* Secrets in AWS Secrets Manager
* IAM-role access for WordPress S3 integration
* Private subnets, VPC endpoints, strict SGs

### ⚙️ Fully Automated with Terraform

* Modular structure
* Remote state per environment
* Minimal manual setup after bootstrap; infrastructure provisioning is automated through Terraform and GitHub Actions.

---

# **Engineering Decisions**

### Disaster Recovery Strategy

Decision:
Adopted a Warm Standby model instead of active-active or fully automated failover

Reason:
To maintain control over stateful components and avoid unsafe automatic recovery

Why not Active-Active:
Active-active introduces complexity in database consistency and conflict resolution

Trade-off:
Slower recovery time vs improved reliability and predictability

### Database Failover

Decision:
The failover is operator-triggered but automated after confirmation.
An operator starts the Step Functions workflow, which promotes the DR replica,
validates database writability, scales ECS in DR, and validates the application.

Reason:
Avoid potential data inconsistency and uncontrolled failover scenarios

Trade-off:
Requires operator intervention during incidents

### Networking Isolation

Decision:
Deploy fully isolated VPCs per region

Reason:
Prevent cross-region blast radius and ensure true regional independence

---

# **Design Principles**

| AWS Well-Architected Pillar | Implementation                                         |
| --------------------------- | ------------------------------------------------------ |
| **Reliability**             | Multi-region, auto failover, RDS replica               |
| **Security**                | HTTPS, IAM roles, secrets manager, least-privilege SGs |
| **Performance**             | CloudFront CDN, S3 media, Fargate                      |
| **Cost-Optimization**       | Warm standby DR, endpoints to reduce NAT traffic       |
| **Operational Excellence**  | Full IaC, zero manual provisioning                     |

---

# **Technology Stack**

### **AWS Services**

* ECS Fargate
* RDS MySQL (Multi-Region)
* S3 (Primary + DR)
* CloudFront CDN
* ALB
* Route 53
* Secrets Manager
* VPC + Endpoints
* CloudWatch + Logs
* ACM (provided or auto-generated)

### **Application Stack**

* WordPress
* WP-CLI
* Amazon S3 / CloudFront plugin
* Hardened `wp-config.php`
* Custom Docker image

---

# **Infrastructure Components**

### 🟦 **1. ECS Fargate WordPress**

* Stateless containers
* Auto-healing
* No EC2 management
* Custom Dockerfile:

  * WP installed via WP-CLI
  * S3 plugin auto-configured
  * Admin URL rewriting
  * HTTPS detection (for CloudFront/ALB)

---

### 🟩 **2. Application Load Balancer**

* HTTPS termination
* Health checks used by CloudFront failover
* Admin subdomain bypasses CloudFront and routes directly to the ALB

---

### 🟥 **3. CloudFront Distribution**

* Two origin groups:

  1. **ALB Primary → ALB DR**
  2. **S3 Primary → S3 DR**
* Default: application traffic
* Ordered: WordPress media uploads
* Full automatic failover
* TLS enabled using ACM

---

### 🟨 **4. RDS MySQL**

* Primary RDS
* DR region read-replica
* Manual promotion during primary region failure

---

### 🟫 **5. S3 Media Storage**

* Two buckets: Primary + DR
* WordPress uploads to primary bucket
* Cross-Region Replication automatically sends objects to DR bucket
* CloudFront serves media via S3 origin group failover
* ECS uses IAM role + VPC endpoint for secure access

Media read failover is automatic through CloudFront S3 origin groups.
Media writes depend on the active ECS region and the configured WordPress/S3 bucket.

---

### 🟪 **6. VPC + Networking**

* Private ECS subnets
* Public ALB subnets
* NAT Gateway minimized
* VPC Endpoints:

  * S3
  * ECR
  * Logs
  * Secrets Manager
  * CloudWatch

* Each region has its own isolated VPC to ensure true regional independence.

---

# **Failover Strategy**

DR is orchestrated using AWS Step Functions:

## Execution Flow
  1. ReplicaFailoverHandler
    * Promotes RDS read replica
  2. ValidateDBWritable
    * Confirms DB is writable
  3. ServiceRecoveryHandler
    * Scales ECS in DR
  4. ValidateApplication
    * Confirms app health via HTTP check

## **1. Application Failover**

Application read traffic can fail over automatically at the CloudFront origin-group layer.
Full application recovery is operator-triggered and automated through Step Functions.

CloudFront Origin Group:

```
Primary ALB → DR ALB
```

Triggers failover on:

* error 5xx
* Timeout
* ALB unreachable
* Security group or NACL issues

---

## **2. Media Failover**

CloudFront S3 Origin Group:

```
Primary S3 → DR S3
```

Read failover is automatic.
Write failover is controlled at ECS task-level.

---

## **3. Database Failover (RDS → DR Region)**

### Default (manual):

* Amazon RDS MySQL (Primary Region)
* Cross-Region Read Replica (DR Region)
* AWS Secrets Manager per region (Primary secret, DR secret)
* ECS Tasks in each region automatically read the correct secret

---

## **4. ECS Failover**

### **Primary Region**
- Runs full production ECS service (ex: 2 tasks)
- Serves all user traffic under normal conditions

### **DR Region (Warm Standby)**
- ECS service is fully deployed but scaled down to 0 tasks.
- This keeps costs minimal while ensuring the infrastructure is ready.

### **Failover Process**
When the primary region becomes unavailable:

1. **CloudFront automatically fails over** to the DR ALB.
2. The DR ECS service is **manually scaled** (or via automation) from 0 to 2 tasks.
3. DR tasks start, register with the DR target group, and immediately begin serving traffic.

This architecture follows AWS Warm Standby DR pattern — a cost-efficient model where the secondary region remains ready but scaled down until failover.

---

# **Failure Scenarios & Recovery**

This section describes how the system behaves under real failure conditions.

### 🌍 Full Region Failure (Primary Down)

- CloudFront automatically routes traffic to DR ALB
- S3 failover ensures media availability
- ECS service in DR must be scaled up manually
- RDS read replica must be promoted

Result:
✔ Application remains available with minimal downtime

---

### 🗄️ Database Failure Only

- Application becomes partially unavailable (WordPress errors)
- Manual promotion of DR replica is required

---

### 📦 S3 Failure

- CloudFront automatically switches to DR bucket
- No data loss due to cross-region replication

---

### ⚠️ Partial Failures (ALB / ECS / Network)

- CloudFront detects unhealthy origin (5xx / timeout)
- Automatically fails over to DR ALB

---

This reflects a controlled disaster recovery model where critical stateful operations remain under operator control.

---

# **Terraform Structure**

```bash
aws-disaster-recovery/
│
├── environments/
│   ├── bootstrap/
│   ├── global/
│   │   ├── iam/
│   │   ├── oac/  
│   │   ├── cdn_dns/
│   ├── primary/
│   │   ├── network/
│   │   ├── rds/
│   │   ├── s3/
│   │   ├── alb/
│   │   ├── ecs/
│   │   └── failover-alarms/     
│   └── dr/
│   │   ├── network/
│   │   ├── read_replica_rds/
│   │   ├── s3/
│   │   ├── alb/
│   │   └── ecs/
│   └── shared_values/
│   │   ├── alb.tfvars/
│   │   └── ecs.tfvars/
│   └── operations/dr_orchestration/
├── modules/
│   ├── acm/
│   ├── alb/
│   ├── cdn_dns/
│   ├── ecs/
│   ├── endpoint/
│   ├── iam/
│   ├── lambda/
│   ├── rds/
│   ├── s3/
│   ├── sg/
│   └── vpc/
├── lambdas/
│   ├── primary-db-setup/
│   ├── replica-failover-handler/
│   ├── service-recovery-handler/
│   ├── validate-application/
│   ├── validate-db-writable/
│   ├── pymysql-layer.zip
├── stepfunctions/
│   ├── dr-failover-orchestrator.asl.json/
└── scripts/
    └── deployment-automation-scripts/
        ├── config.sh
        ├── deploy.sh
        ├── destroy.sh
        ├── pull-docker-hub-to-ecr.sh
        └── stacks_config.sh
    

```
This structure prevents dependency cycles and allows independent region deployments.

---

# **CI/CD Strategy**

Infrastructure deployment is fully automated using GitHub Actions with OpenID Connect (OIDC).

### Key Characteristics

  - No static AWS credentials are used
  - GitHub Actions assumes IAM role dynamically
  - Terraform is executed in a controlled pipeline
  - Deploy and destroy workflows are separated

### Deployment Flow

  1. Developer triggers workflow manually
  2. GitHub Actions authenticates to AWS using OIDC
  3. Terraform applies infrastructure across:
     - Primary region
     - DR region
     - Global services (CloudFront, Route53)

This approach ensures secure, repeatable, and production-grade infrastructure delivery.

---

## Cross-Stack Dependency Map

This project uses multiple Terraform stacks.  
A detailed diagram of how stack outputs flow between stacks is available here:

👉 [Cross-Stack Variable Flow](docs/cross-stack-flow.md)

--- 

# **Reviewer Setup (How to Deploy This Project in Your AWS Account)** 

This section explains exactly how to deploy and test the full multi-region WordPress DR architecture in your own AWS account, with no AWS access keys and no manual Terraform commands (after bootstrap).

The setup is intentionally simple and follows AWS + GitHub industry CI/CD patterns.
## ✅ 1. Requirements

You need:

✔ AWS account
with permissions to create IAM, VPC, ECS, RDS, S3, CloudFront, ALB, Route53.

✔ A Route53 hosted zone
for your domain (example: yourdomain.com).

✔ (Optional) ACM certificates
If you don’t provide them, the infrastructure will create them automatically.

## 🚀 2. Clone the Project

No fork needed:
```bash
git clone https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr.git
cd aws-multi-region-wordpress-dr
```

## 🟦 3. Deploy the Bootstrap Stack (ONE TIME ONLY)

This step enables GitHub Actions OIDC → AWS IAM, allowing GitHub to deploy in your AWS account without any access keys.

✔ What bootstrap creates:

|              Resource                      |                            Purpose                                   |
| ------------------------------------------ | -------------------------------------------------------------------- |
| AWS IAM OpenID Connect Provider (GitHub)   | Allow GitHub Actions to authenticate to AWS                          |
| GitHub Actions IAM role                    | This is assumed by the deploy/destroy workflows                      |
| Trust policy restricted to the repository  | security-hardening: only our repository can use this role            |
| AdministratorAccess policy                 | Full deploy/destroy capabilities (reviewer may restrict this later)  |

⚠️ Important — Update Repository Name Before Deploying Bootstrap

The IAM trust policy created in this step is restricted to a single GitHub repository.
If you cloned this project into your own GitHub account, you MUST update the repository name in this file:
```bash
environments/bootstrap/main.tf
```
find:
```bash
"token.actions.githubusercontent.com:sub" = "repo:qays317/review-test:*"
```
➡ Replace with your repository identifier:
```bash
repo:<username>/<repository-name>
```
If you don’t update this, GitHub Actions will fail with:

Not authorized to assume role

Step 3.1 — Authenticate to AWS locally

Either:
```bash
aws configure
```
or
```bash
export AWS_ACCESS_KEY_ID=xxxx
export AWS_SECRET_ACCESS_KEY=xxxx
export AWS_DEFAULT_REGION=us-east-1
```
Step 3.2 — Deploy bootstrap
```bash
terraform -chdir=environments/bootstrap init
terraform -chdir=environments/bootstrap apply
```
You will receive an output:
```bash
github_actions_role_arn = arn:aws:iam::<ACCOUNT-ID>:role/github-actions-terraform-role
```

## 🟩 4. Add the Role ARN to GitHub Actions Workflows

You do NOT need GitHub secrets.

Just open:
```bash
.github/workflows/deploy.yml  
.github/workflows/destroy.yml
```
Find:
```bash
role-to-assume: arn:aws:iam::<ACCOUNT-ID>:role/github-actions-terraform-role
```
Replace <ACCOUNT-ID> with your AWS account ID.

✔ This is all GitHub needs.
✔ No secrets.
✔ No PAT.
✔ No long-lived keys.
✔ Secure and industry-standard.

## 🟧 5. Configure Deployment Parameters

Open:
```bash
scripts/deployment-automation-scripts/config.sh
```
Edit values to match your AWS environment:
| Variable                        | Purpose                                                                               |
|---------------------------------|---------------------------------------------------------------------------------------|
| PRIMARY_REGION                  | AWS region for the primary deployment (e.g., us-east-1)                               | 
| DR_REGION                       | AWS region for the DR deployment (e.g., ca-central-1)                                 |
| TF_STATE_BUCKET_NAME            | S3 bucket used for ALL Terraform remote state                                         |
| TF_STATE_BUCKET_REGION          | Region of the Terraform state bucket                                                  | 
| PRIMARY_DOMAIN                  | Root domain (e.g., example.com)                                                       |
| HOSTED_ZONE_ID                  | Route53 hosted zone ID for the domain                                                 |
| PRIMARY_MEDIA_S3_BUCKET         | Name of primary S3 bucket for media                                                   |
| DR_MEDIA_S3_BUCKET              | Name of DR S3 media bucket                                                            |
| PRIMARY_ALB_SSL_CERTIFICATE_ARN | ARN of primary ALB ACM certificate (empty = auto-create with ACM module)              |
| DR_ALB_SSL_CERTIFICATE_ARN      | ARN of DR ALB ACM certificate (empty = auto-create with ACM module)                   |
| CLOUDFRONT_SSL_CERTIFICATE_ARN  | ACM certificate ARN in us-east-1 for CloudFront (empty = auto-create with ACM module) |
| CERTIFICATE_SANs                | Alternative subjects names for SSL certificate                                        |

If you leave any certificate ARN empty, Terraform automatically creates certificates for you.

## 🚀 6. Deploy the Multi-Region Infrastructure

From GitHub → Actions:

✔ Go to:

Deploy AWS Disaster Recovery → Run workflow

GitHub will automatically:

✓ Assume the IAM role you created

✓ Load config.sh

✓ Mirror the Docker image → ECR (Primary + DR)

✓ Deploy the Primary region

✓ Deploy the DR region

✓ Deploy CloudFront + Route53 global stack

✓ Output WordPress endpoints

Total time ~ 50 minutes


### ✓ 🐳 Docker Image Mirroring (Helper Script)

During deployment, the main script:

```bash
scripts/deployment-automation-scripts/deploy.sh
```
internally calls the helper script:
```bash
scripts/deployment-automation-scripts/pull-docker-hub-to-ecr.sh <aws-region> <environment>
```
This helper script is fully automated and:

1. Pulls the WordPress image from Docker Hub defined in config.sh (DOCKERHUB_IMAGE)
2. Ensures the ECR repository exists (ECR_REPO_NAME)
3. Tags and pushes the image to:
```bash
<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/ecs-wordpress-app:<TAG>
```
4. Writes the final ECR image URI to:
```bash
scripts/runtime/primary-ecr-image-uri
scripts/runtime/dr-ecr-image-uri
```
The ECS task definitions in both regions then read the correct image URI from these runtime files, so the reviewer does not need to manage image tags manually.

### 🔐 WordPress Admin Credentials

After the infrastructure deployment completes and WordPress is fully initialized, you can log in to the WordPress admin dashboard using the following 

**default credentials**:

```text
Username: admin
Password: Admin123!
```
**Login URL**:

```text
https://<your-domain>/wp-admin
```

---

## 💣 8. Destroy the Infrastructure

From GitHub → Actions:

Destroy AWS Disaster Recovery → Run workflow

This destroys resources in the correct dependency order:

* ECS
* ALBs
* RDS
* VPC
* CloudFront + Route53
* Cleanup ECR pushed images
* Remove runtime state

This ensures a clean teardown with no orphaned resources.

---

# **CloudWatch Monitoring and Alarms**

This project implements centralized observability using Amazon CloudWatch.
The automation layer consists of a one-time Lambda invocation used only during initial infrastructure provisioning.

✔ ECS Logging

Each ECS task writes logs to a dedicated CloudWatch Log Group:
* Log group name pattern:
"/ecs/<task-family-name>"
* Logs retained for 7 days
* Automatically created for each ECS task definition via Terraform

This provides container-level logs for debugging application issues, deployment behavior, or failover events.

✔ ECS Health Alarm (via ALB Target Group)

To ensure service health and detect issues early, a CloudWatch alarm is configured for the Application Load Balancer (ALB) Target Group:
* Alarm name: wordpress-health-alarm
* Metric: HealthyHostCount (AWS/ApplicationELB)
* Trigger:
  * Alarm fires when healthy container count drops below 2
  * Metric evaluated every 60 seconds
  * treat_missing_data = "breaching" ensures that missing ALB metrics during failure also trigger the alarm
* Dimensions:
  * TargetGroup ARN suffix
  * LoadBalancer ARN suffix
* Purpose:
 * Detects failing ECS tasks or unhealthy containers behind the ALB, enabling early detection of service degradation

✔ Lambda Execution Logging

The database-initialization Lambda function (wordpress-db-setup) includes full log coverage:
* Log group:
  * "/aws/lambda/wordpress-db-setup"
* Log retention: 7 days
* All Lambda execution output (including errors, DB setup output, Secrets Manager interactions) is logged
* Logs assist in debugging database bootstrap, credential provisioning, and RDS post-creation automation

The database-initialization Lambda function is invoked synchronously by Terraform during the initial terraform apply, immediately after the RDS instance is created.

This automation is intentionally designed to run only during initial provisioning. Future schema changes or migrations are expected to be handled via application-level processes or CI/CD pipelines.

---

# **Security Best Practices Used**

* TLS 1.2+ enforced
* HTTPS for admin + frontend
* Private database
* Security Groups use least privilege
* Secrets stored in Secrets Manager
* IAM roles used instead of access keys
* S3 buckets private (CloudFront handles access)
* Apache SSL disabled inside container (ALB handles TLS)

---

# **Cost Optimization**

This architecture follows a Warm Standby DR model to significantly reduce multi-region cloud expenses.

Primary Region (Active) — Estimated Monthly Cost
| Component  | Service                              | Approx Monthly Cost       |
| ---------- |--------------------------------------|---------------------------|
| Compute    | ECS Fargate tasks (1–2 tasks)        | $40–$80                   |
| Database   | RDS MySQL (db.t3.medium)             | $120–$150                 |  
| Storage    | S3 buckets + backups                 | $5–$15                    |
| Networking | ALB + VPC Endpoints (No NAT Gateway) | $7-$20                    |
| Traffic    | CloudFront distribution              | $10-$30                   |
| Monitoring | CloudWatch metrics, logs & alarms    | $5-$10                    |

Total Primary Region:
👉 $187–$305 per month

DR Region (Warm Standby) — Estimated Monthly Cost
| Component       | Service                              | Cost Behavior           | Approx Monthly Cost       |
| --------------- |--------------------------------------|-------------------------|---------------------------|
| Compute         | ECS Fargate tasks                    | Scaled to 0 (normal)    | $0                        |
| Database        | RDS cross-region read replica        | reqiured                | $120–$150                 |  
| Storage         | S3 replication target                | Minimal                 | $3-$10                    |
| Networking      | ALB + VPC Endpoints (No NAT Gateway) | Low                     | $18-$30                   |
| Traffic         | CloudFront distribution              | Shared                  | $0                        |
| Logs/Monitoring | CloudWatch                           | Small volume            | $3-$6                     |
Note:
ECS tasks in the DR region are scaled to zero during normal operation.
They scale up to two tasks only during a failover event, so DR compute cost is effectively zero until activation.

Total DR Region:
👉 $145–$196 per month

Total Multi-Region Cost
Primary ($187–$305) + DR ($145–$196)
👉 Estimated Total: $332–$501 per month

---

# **Known Limitations and Trade-offs**

These limitations are intentional and reflect real-world engineering trade-offs rather than incomplete implementation.
This project implements a realistic multi-region DR (Disaster Recovery) architecture using a Warm Standby strategy. While effective and cost-efficient, it includes several intentional trade-offs and limitations that are important to understand.

### 1. Manual RDS Failover (Replica Promotion)

* The cross-region RDS replica does not automatically become primary.
* In a region-wide failure, an operator must manually promote the read replica in the DR region.
* This introduces a small delay (RTO) until the database becomes writable again.

  Trade-off:
  Automatic failover reduces downtime but increases complexity and cost. Manual promotion is simpler and appropriate for warm-standby DR.

### 2. RDS Replication Lag (RPO > 0)

* Cross-region MySQL replication introduces replication lag of seconds to minutes depending on load.
* During failover, the DR region may lose very recent writes.

  Trade-off:
  Achieving zero data loss requires synchronous replication or multi-master setups, which are significantly more expensive.

### 3. ECS DR Cluster is Warm, Not Active

* ECS tasks in the DR region are scaled down to 0 (or minimal) until failover.
* A failover event requires scaling ECS services up, which adds delay before full recovery.

  Trade-off:
  Warm standby reduces cost by 50–70% compared to active-active multi-region setups.

### 4. Health checks do not validate the database layer

* CloudFront + ALB health checks validate HTTP availability, not database availability.
* If ALB/ECS is healthy but RDS is down, users may still see WordPress errors.

  Trade-off: End-to-end DB health checks require custom application endpoints or deeper monitoring.
  For simplicity, this solution checks only at the HTTP level.

### 5. Lambda Automation Runs Once (Bootstrap Only)

* The DB setup Lambda runs only during initial deployment.
* Schema migrations or future DB updates must be handled manually or using a CI/CD process.

  Trade-off:
  Automating migrations adds complexity (Liquibase, Flyway, custom pipelines), so bootstrap-only logic keeps the project simple.

### 6. S3 Replication Provides Eventual Consistency

* S3 Cross-Region Replication (CRR) is asynchronous.
* Media files may take seconds or minutes to appear in the DR region after upload.

  Trade-off:
  Fully synchronous replication for media storage is expensive and not supported natively by S3.

### 7. Failover Decision Is Operator-Driven

* This DR design intentionally avoids auto-failover to prevent false positives.
* Failover requires human confirmation.

  Trade-off:
  Auto-failover is fast but risks flipping regions due to transient issues. Warm-standby DR normally uses controlled manual failover.

### 8. No Fully Automated DR Drills

* Disaster Recovery drills (regional failure simulations) must be executed manually.
* Automated DR testing pipelines are not included.

  Trade-off:
  Automation adds complexity; manual testing remains common in warm standby setups.

### 9. DR ALB Always Running

* The DR region's ALB is always provisioned to allow immediate failover.
* This introduces a small fixed cost even when the region is idle.

  Trade-off:
  Keeping the ALB "cold" would save money but increases RTO (longer DR recovery time).

### 10. IAM & RDS Secrets Manager – Region-Specific Consistency Trade-off
This limitation documents a region-specific consistency behavior observed when using
Amazon RDS–managed Secrets Manager credentials together with tag-based IAM conditions.

While tag-based access control worked reliably in `us-east-1`, it caused non-deterministic
failures in other regions (e.g. `us-east-2`) due to eventual consistency in AWS-managed
secret creation and tag propagation.

As a result, this project intentionally prioritizes deterministic, region-safe IAM policies
over tag-based conditions for RDS-managed secrets.

#### Background

This project uses Amazon RDS with `manage_master_user_password = true`, which instructs AWS
to automatically generate and manage the database master credentials in AWS Secrets Manager.

The secret is created and owned by Amazon RDS, not by Terraform or the application.

---

Initial Security Approach (Tag-Based IAM Conditions)

To follow least-privilege IAM principles, the Lambda function responsible for initializing the WordPress database was originally restricted using resource tags on the RDS-generated secret.

Example IAM policy (initial attempt)

```bash 
# RDS auth secret (master password)
{
  Effect = "Allow"
  Action = [
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret"
  ]
  Resource = ["arn:aws:secretsmanager:${var.primary_region}:${data.aws_caller_identity.current.account_id}:secret:*"],
  Condition = {
    StringEquals = {
      "aws:ResourceTag/Project" = "wordpress",
      "aws:ResourceTag/Component" = "rds-auth"
    }
  }
}
```


Terraform attempted to tag the RDS-managed secret immediately after the database was created:

```bash
resource "null_resource" "tag_rds_master_secret" {
  triggers = {
    secret = aws_db_instance.rds.master_user_secret[0].secret_arn
  }

  provisioner "local-exec" {
    command = <<EOT
aws secretsmanager tag-resource \
  --secret-id ${aws_db_instance.rds.master_user_secret[0].secret_arn} \
  --tags Key=Project,Value=wordpress Key=Component,Value=rds-auth
EOT
  }
}
```
--- 

Observed Behavior

✅ In us-east-1: 

  * This approach worked reliably across multiple deployments.

❌ In us-east-2 (and other regions): 

  * Terraform failed with the following error:

```bash
An error occurred (ResourceNotFoundException) when calling the TagResource operation:
Secrets Manager can't find the specified secret.
```

This occurred even though:

  * The secret did exist

  * The secret was visible in the AWS Console

  * The ARN was correct

  * The RDS instance had completed creation

---

Root Cause (AWS Service Behavior)

This is a region-dependent AWS behavior, not a Terraform bug.

Key facts:

  * RDS-managed secrets are created asynchronously

  * Tag propagation and tag visibility are eventually consistent

  * AWS does not guarantee immediate tag availability for service-managed secrets

  * IAM tag-based conditions may be evaluated before tags are visible

  * Behavior is not consistent across regions

As a result:

  * Lambda was denied access because the tag condition could not be evaluated

  * Even though the secret existed, AWS treated it as not matching the IAM policy

  * This caused non-deterministic failures outside us-east-1

---

Final Design Decision (Production-Safe)

To ensure deterministic and region-safe deployments, the project intentionally does not rely on tag-based IAM conditions for RDS-managed secrets.

Instead, access is restricted by:

  * Account

  * Region

  * Secret ARN pattern

Final IAM policy (used in this project)
```bash
  # RDS auth secret (master password)
  {
    Effect = "Allow"
    Action = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    Resource = ["arn:aws:secretsmanager:${var.primary_region}:${data.aws_caller_identity.current.account_id}:secret:*"]
  }
```
Why This Is the Correct Approach

✔ Deterministic across all AWS regions

✔ No race conditions during provisioning

✔ Works reliably in CI/CD pipelines

✔ Still enforces strong isolation (account + region scoped)

✔ Aligns with AWS ownership model for service-managed resources

AWS Well-Architected guidance favors reliability and predictability over brittle, timing-sensitive IAM conditions — especially for resources created and controlled by AWS services.

---

Summary

These trade-offs make the solution:
Reliable
Realistic
Cost-effective

Aligned with AWS Well-Architected DR patterns (Warm Standby)

But they also mean the system is not active-active and sacrifices some speed and automation in exchange for simplicity and affordability.

--- 

# **License**

This project is open for personal and educational use.

---

