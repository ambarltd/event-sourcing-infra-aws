# Ambar AWS Event Sourcing Application Terraform Module

A comprehensive Terraform module for deploying event sourcing applications on AWS using modern cloud-native services and infrastructure as code.

## Overview

This Terraform module provides a complete infrastructure foundation for event sourcing applications. It creates and manages all necessary AWS resources, third-party integrations, and networking components required for a production-ready event sourcing architecture.

### Infrastructure Components

The module creates the following infrastructure:

- **VPC & Networking**: Secure VPC with public/private subnets across multiple AZs, security groups, and internet gateway
- **Event Store**: AWS RDS PostgreSQL database for event stream storage with automated backups
- **Projection Store**: MongoDB Atlas cluster for read model projections with connection credentials
- **Container Services**: AWS ECS clusters with ALB/NLB for frontend and backend services
- **Container Registry**: AWS ECR repositories with GitHub OIDC integration for CI/CD
- **Object Storage**: S3 buckets for static assets with lifecycle policies and versioning
- **Email Service**: AWS SES with domain verification, DKIM, and SMTP credentials
- **Domain Management**: Route53 hosted zone with DNS records for domain setup
- **Event Streaming**: Ambar Cloud integration for real-time event transmission
- **Monitoring**: CloudWatch logs, metrics, and SNS alerts for system monitoring

### Module Usage

```hcl
module "event_sourcing_app" {
  source = "github.com/your-org/event-sourcing-infra-aws/terraform"
  
  # CRITICAL: 2-Step Deployment Process
  # STEP 1: Deploy with nameserver_records_completed = false (default)
  # This creates only the Route53 hosted zone
  # STEP 2: After configuring nameservers at your domain registrar:
  # 1. Get nameservers from terraform output: domain_name_servers
  # 2. Configure them at your domain registrar (GoDaddy, Namecheap, etc.)
  # 3. Wait for DNS propagation (can take up to 48 hours)
  # 4. Set nameserver_records_completed = true and redeploy
  nameserver_records_completed = false  # default: false

  # Required AWS Configuration
  region                             = "eu-west-1"
  application_account_aws_access_key = var.aws_access_key
  application_account_aws_secret_key = var.aws_secret_key

  # Required MongoDB Atlas Configuration
  mongodbatlas_public_key  = var.mongodb_public_key
  mongodbatlas_private_key = var.mongodb_private_key
  mongodbatlas_project_id  = var.mongodb_project_id

  # Required Ambar Configuration
  ambar_api_key             = var.ambar_api_key
  ambar_regional_endpoint   = "euw1.api.ambar.cloud"
  destination_endpoints_to_descriptions = {
    "/projections/users"         = "User projection endpoint"
    "/projections/orders"        = "Order projection endpoint"
    "/reactions/notifications"   = "Notification reaction endpoint"
    "/reactions/email-triggers"  = "Email trigger reaction endpoint"
  }

  # Required Domain Configuration
  domain                      = "example.com"
  frontend_domain            = "app.example.com"
  backend_application_domain = "api.example.com"
  from_email                 = "notifications@example.com"

  # Required GitHub Integration
  github_frontend_repo = "frontend-app"
  github_backend_repo  = "backend-api"

  # Required Application Images
  frontend_image = "a6c58d7df3ea76c5463161eae6c201659e397ece"
  backend_image  = "a6c58d7df3ea76c5463161eae6c201659e397ece"

  # Optional GitHub Configuration (with defaults shown)
  github_org                        = "your-github-org"  # default: "ambarltd"
  github_frontend_repo_prod_branch  = "main"             # default: "main"
  github_backend_repo_prod_branch   = "production"       # default: "main"

  # Optional Frontend Configuration (with defaults shown)
  frontend_application_port = 8080  # default: 8080
  frontend_cpu_capacity     = 512   # default: 256
  frontend_mem_capacity     = 1024  # default: 512
  frontend_instance_count   = 2     # default: 0
  additional_frontend_domains = [
    "www.example.com",
    "staging.example.com"
  ]  # default: []

  # Optional Backend Configuration (with defaults shown)
  backend_application_port = 3000  # default: 3000
  backend_cpu_capacity     = 1024  # default: 512
  backend_mem_capacity     = 2048  # default: 1024
  backend_instance_count   = 3     # default: 0

  # Optional Monitoring Configuration (with defaults shown)
  emails_for_alerts = [
    "admin@example.com",
    "ops@example.com",
    "devops@example.com"
  ]  # default: []
}
```

## Requirements

| Name | Version |
|------|---------|
| [terraform](#requirement\_terraform) | >= 1.0.0 |
| [aws](#requirement\_aws) | 5.90.0 |
| [random](#requirement\_random) | >= 3.1.0 |
| [mongodbatlas](#requirement\_mongodbatlas) | >= 1.4.0 |
| [ambar](#requirement\_ambar) | >= 1.0.11 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy resources | `string` | n/a | yes |
| <a name="input_application_account_aws_access_key"></a> [application\_account\_aws\_access\_key](#input\_application\_account\_aws\_access\_key) | AWS Access Key | `string` | n/a | yes |
| <a name="input_application_account_aws_secret_key"></a> [application\_account\_aws\_secret\_key](#input\_application\_account\_aws\_secret\_key) | AWS Secret Access Key | `string` | n/a | yes |
| <a name="input_mongodbatlas_public_key"></a> [mongodbatlas\_public\_key](#input\_mongodbatlas\_public\_key) | MongoDB Atlas public API key | `string` | n/a | yes |
| <a name="input_mongodbatlas_private_key"></a> [mongodbatlas\_private\_key](#input\_mongodbatlas\_private\_key) | MongoDB Atlas private API key | `string` | n/a | yes |
| <a name="input_mongodbatlas_project_id"></a> [mongodbatlas\_project\_id](#input\_mongodbatlas\_project\_id) | MongoDB Atlas Project Identifier | `string` | n/a | yes |
| <a name="input_ambar_api_key"></a> [ambar\_api\_key](#input\_ambar\_api\_key) | API key for Ambar provider | `string` | n/a | yes |
| <a name="input_ambar_regional_endpoint"></a> [ambar\_regional\_endpoint](#input\_ambar\_regional\_endpoint) | The regional api endpoint for Ambar to use | `string` | n/a | yes |
| <a name="input_destination_endpoints_to_descriptions"></a> [destination\_endpoints\_to\_descriptions](#input\_destination\_endpoints\_to\_descriptions) | Map of projection and reaction endpoints with key as path and value as a description | `map(string)` | n/a | yes |
| <a name="input_frontend_domain"></a> [frontend\_domain](#input\_frontend\_domain) | Frontend domain name | `string` | n/a | yes |
| <a name="input_backend_application_domain"></a> [backend\_application\_domain](#input\_backend\_application\_domain) | Backend application domain name | `string` | n/a | yes |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organization name | `string` | `"ambarltd"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Common domain name | `string` | n/a | yes |
| <a name="input_github_frontend_repo"></a> [github\_frontend\_repo](#input\_github\_frontend\_repo) | GitHub repository name for frontend | `string` | n/a | yes |
| <a name="input_github_frontend_repo_prod_branch"></a> [github\_frontend\_repo\_prod\_branch](#input\_github\_frontend\_repo\_prod\_branch) | Production branch for frontend repository | `string` | `"main"` | no |
| <a name="input_frontend_image"></a> [frontend\_image](#input\_frontend\_image) | Frontend container image | `string` | n/a | yes |
| <a name="input_frontend_application_port"></a> [frontend\_application\_port](#input\_frontend\_application\_port) | Frontend application port | `number` | `8080` | no |
| <a name="input_frontend_cpu_capacity"></a> [frontend\_cpu\_capacity](#input\_frontend\_cpu\_capacity) | Frontend CPU capacity | `number` | `256` | no |
| <a name="input_frontend_mem_capacity"></a> [frontend\_mem\_capacity](#input\_frontend\_mem\_capacity) | Frontend memory capacity | `number` | `512` | no |
| <a name="input_frontend_instance_count"></a> [frontend\_instance\_count](#input\_frontend\_instance\_count) | Frontend instance count | `number` | `0` | no |
| <a name="input_additional_frontend_domains"></a> [additional\_frontend\_domains](#input\_additional\_frontend\_domains) | Additional frontend domains | `list(string)` | `[]` | no |
| <a name="input_github_backend_repo"></a> [github\_backend\_repo](#input\_github\_backend\_repo) | GitHub repository name for backend | `string` | n/a | yes |
| <a name="input_github_backend_repo_prod_branch"></a> [github\_backend\_repo\_prod\_branch](#input\_github\_backend\_repo\_prod\_branch) | Production branch for backend repository | `string` | `"main"` | no |
| <a name="input_backend_image"></a> [backend\_image](#input\_backend\_image) | Backend container image | `string` | n/a | yes |
| <a name="input_backend_application_port"></a> [backend\_application\_port](#input\_backend\_application\_port) | Backend application port | `number` | `3000` | no |
| <a name="input_backend_cpu_capacity"></a> [backend\_cpu\_capacity](#input\_backend\_cpu\_capacity) | Backend CPU capacity | `number` | `512` | no |
| <a name="input_backend_mem_capacity"></a> [backend\_mem\_capacity](#input\_backend\_mem\_capacity) | Backend memory capacity | `number` | `1024` | no |
| <a name="input_backend_instance_count"></a> [backend\_instance\_count](#input\_backend\_instance\_count) | Backend instance count | `number` | `0` | no |
| <a name="input_from_email"></a> [from\_email](#input\_from\_email) | From email address | `string` | n/a | yes |
| <a name="input_emails_for_alerts"></a> [emails\_for\_alerts](#input\_emails\_for\_alerts) | List of email addresses for alerts | `list(string)` | `[]` | no |
| <a name="input_nameserver_records_completed"></a> [nameserver\_records\_completed](#input\_nameserver\_records\_completed) | CRITICAL: Only the Route53 HostedZone will be created until this variable is set to true. Use the NameServer dns entries from the terraform outputs to update the registrar where your domain is managed to allow for further resources to be created using it. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain_name_servers"></a> [domain\_name\_servers](#output\_domain\_name\_servers) | Name servers for the hosted zone - CRITICAL: Configure these at your domain registrar |
| <a name="output_frontend_url"></a> [frontend\_url](#output\_frontend\_url) | URL of the frontend application |
| <a name="output_backend_url"></a> [backend\_url](#output\_backend\_url) | URL of the backend API |
| <a name="output_frontend_ecr_repository_url"></a> [frontend\_ecr\_repository\_url](#output\_frontend\_ecr\_repository\_url) | ECR repository URL for frontend container images |
| <a name="output_backend_ecr_repository_url"></a> [backend\_ecr\_repository\_url](#output\_backend\_ecr\_repository\_url) | ECR repository URL for backend container images |
| <a name="output_frontend_github_role_arn"></a> [frontend\_github\_role\_arn](#output\_frontend\_github\_role\_arn) | GitHub Actions assumable role ARN for frontend CI/CD |
| <a name="output_backend_github_role_arn"></a> [backend\_github\_role\_arn](#output\_backend\_github\_role\_arn) | GitHub Actions assumable role ARN for backend CI/CD |
| <a name="output_event_store_endpoint"></a> [event\_store\_endpoint](#output\_event\_store\_endpoint) | RDS PostgreSQL endpoint for event store (sensitive) |
| <a name="output_mongodb_cluster_name"></a> [mongodb\_cluster\_name](#output\_mongodb\_cluster\_name) | MongoDB Atlas cluster name for projections |
| <a name="output_mongodb_cluster_id"></a> [mongodb\_cluster\_id](#output\_mongodb\_cluster\_id) | MongoDB Atlas cluster ID |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | S3 bucket name for object storage |
| <a name="output_s3_bucket_domain"></a> [s3\_bucket\_domain](#output\_s3\_bucket\_domain) | S3 bucket domain name for direct access |
| <a name="output_allowed_from_addresses"></a> [allowed\_from\_addresses](#output\_allowed\_from\_addresses) | List of verified email addresses for SES sending |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID for the infrastructure |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR block of the VPC |
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | Availability zones used by the infrastructure |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnet IDs |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs |
| <a name="output_frontend_cluster_name"></a> [frontend\_cluster\_name](#output\_frontend\_cluster\_name) | ECS cluster name for frontend service |
| <a name="output_backend_cluster_name"></a> [backend\_cluster\_name](#output\_backend\_cluster\_name) | ECS cluster name for backend service |
| <a name="output_frontend_service_name"></a> [frontend\_service\_name](#output\_frontend\_service\_name) | ECS service name for frontend |
| <a name="output_backend_service_name"></a> [backend\_service\_name](#output\_backend\_service\_name) | ECS service name for backend |
| <a name="output_frontend_log_group_name"></a> [frontend\_log\_group\_name](#output\_frontend\_log\_group\_name) | CloudWatch log group name for frontend service |
| <a name="output_backend_log_group_name"></a> [backend\_log\_group\_name](#output\_backend\_log\_group\_name) | CloudWatch log group name for backend service |
| <a name="output_setup_instructions"></a> [setup\_instructions](#output\_setup\_instructions) | Critical setup steps required after infrastructure deployment |
