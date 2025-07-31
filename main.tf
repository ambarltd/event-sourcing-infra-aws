# Local values for computed domain names
locals {
  backend_domain  = var.backend_application_domain_prefix != "" ? "${var.backend_application_domain_prefix}.${var.top_level_domain}" : "api.${var.top_level_domain}"
  frontend_domain = var.frontend_application_domain_prefix != "" ? "${var.frontend_application_domain_prefix}.${var.top_level_domain}" : var.top_level_domain
}

##############################################################################
# FOUNDATIONAL INFRASTRUCTURE
##############################################################################

# Creates VPC, subnets, security groups, and internet gateway
# Provides the networking foundation for all other resources
module "network" {
  source = "./terraform/network"

  providers = {
    aws = aws.main
  }

  environment_name = var.environment_name
  region           = var.region

  # Network configuration - explicit for visibility and customization
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["a", "b", "c"]  # Creates subnets in 3 AZs for high availability
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  application_ports = [var.frontend_application_port, var.backend_application_port]
}

# SES domain verification, and SMTP credentials
# Handles all email sending capabilities and DNS management for the domain
module "email" {
  source = "./terraform/email"

  environment_name      = var.environment_name
  domain_name           = var.top_level_domain
  route53_zone_name     = var.hosted_zone_name
  route53_zone_id       = var.hosted_zone_id
  allowed_from_address  = var.from_email

  providers = {
    aws            = aws.main,
    aws.alt_region = aws.alt_region  # SES may require alternate region for setup
  }
}

##############################################################################
# DATA STORES
##############################################################################

# Creates Aurora PostgreSQL cluster for event sourcing with logical replication
# Automatically configures schema, indexes, replication user, and publication for Ambar
module "event_store" {
  source = "./terraform/event_store"

  providers = {
    aws = aws.main
  }

  environment_name    = var.environment_name
  region              = var.region
  vpc_id              = module.network.vpc_id
  database_subnet_ids = module.network.public_subnet_ids
}

# Creates MongoDB Atlas cluster for read model projections
# Provides scalable document storage for query-optimized data views
module "projection_store" {
  source = "./terraform/projection_store"

  environment_name  = var.environment_name
  atlas_project_id  = var.mongodbatlas_project_id
  mongodb_version   = "7.0"
  region            = var.region
  mongodb_free_tier = var.mongodbatlas_free_tier

  depends_on = [module.network]
}

# Creates S3 bucket with lifecycle policies for object storage
# Handles file uploads, static assets, and blob storage needs
module "object_storage" {
  source = "./terraform/object_storage"

  providers = {
    aws = aws.main
  }

  environment_name     = var.environment_name
  frontend_cors_domain = local.frontend_domain

  # S3 configuration - explicit for visibility and customization
  enable_versioning                  = true
  lifecycle_enabled                  = true
  noncurrent_version_expiration_days = 90
}

##############################################################################
# CONTAINER REGISTRIES
##############################################################################

# Creates ECR repository and GitHub OIDC role for backend application
# Enables GitHub Actions to build and push Docker images for backend services
module "backend_image_registry" {
  source = "./terraform/image_registry"

  providers = {
    aws = aws.main
  }

  environment_name                           = var.environment_name
  ecr_repo_name                              = "event-sourcing-app-backend"
  github_organization_with_read_write_access = var.github_organization_with_read_write_access
  github_repository_with_read_write_access   = var.backend_github_repository_with_read_write_access
  github_branch_with_read_write_access       = var.backend_github_branch_with_read_write_access
}

# Creates ECR repository and GitHub OIDC role for frontend application
# Enables GitHub Actions to build and push Docker images for frontend services
module "frontend_image_registry" {
  source = "./terraform/image_registry"

  providers = {
    aws = aws.main
  }

  environment_name                           = var.environment_name
  ecr_repo_name                              = "event-sourcing-app-frontend"
  github_organization_with_read_write_access = var.github_organization_with_read_write_access
  github_repository_with_read_write_access   = var.frontend_github_repository_with_read_write_access
  github_branch_with_read_write_access       = var.frontend_github_branch_with_read_write_access
}

##############################################################################
# APPLICATION SERVICES
##############################################################################

# Creates ECS cluster, service, and NLB for backend API application
# Provides scalable container hosting with automatic scaling and health checks
module "backend_container_service" {
  source = "./terraform/backend_service"

  providers = {
    aws = aws.main
  }

  environment_name      = var.environment_name
  region                = var.region
  backend_domain        = local.backend_domain
  frontend_domain       = local.frontend_domain
  hosted_zone_id        = var.hosted_zone_id
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  ecs_security_group_id = module.network.ecs_security_group_id

  # Container configuration
  container_image     = var.backend_image
  ecr_repository_name = module.backend_image_registry.ecr_repository_name
  container_port      = var.backend_application_port
  health_check_path   = "/"
  container_cpu       = var.backend_cpu_capacity
  container_memory    = var.backend_mem_capacity

  # Integrations with other services
  blob_storage_bucket_name = module.object_storage.bucket_name
  blob_storage_bucket_arn  = module.object_storage.bucket_arn
  s3_access_key_id         = module.object_storage.s3_access_key_id
  s3_secret_access_key     = module.object_storage.s3_secret_access_key

  # Event Store Configuration
  event_store_endpoint = module.event_store.event_store_endpoint
  event_store_port     = 5432
  event_store_username = module.event_store.event_store_user
  event_store_password = module.event_store.event_store_password

  # MongoDB Projection Store Configuration
  mongodb_host     = module.projection_store.srv_connection_host
  mongodb_port     = 27017  # Not used when SRV connection string is provided
  mongodb_username = module.projection_store.projection_store_user
  mongodb_password = module.projection_store.projection_store_password

  # SMTP Configuration
  smtp_host       = module.email.smtp_host
  smtp_port       = module.email.smtp_port
  smtp_username   = module.email.smtp_username
  smtp_password   = module.email.smtp_password
  smtp_from_email = var.from_email

  # Conditional deployment - only create instances if image is provided
  desired_count = var.backend_image != "" ? var.backend_instance_count : 0

  log_retention_days    = 90
  environment_variables = var.backend_environment_variables

  depends_on = [
    module.network,
    module.event_store,
    module.object_storage,
    module.backend_image_registry,
    module.projection_store,
    module.email
  ]
}

# Creates ECS cluster, service, and ALB for frontend web application
# Provides scalable container hosting with CDN-ready static asset serving
module "frontend_container_service" {
  source = "./terraform/frontend_service"

  providers = {
    aws = aws.main
  }

  environment_name      = var.environment_name
  region                = var.region
  backend_endpoint      = local.backend_domain
  frontend_domain       = local.frontend_domain
  additional_domains    = var.additional_frontend_domains
  hosted_zone_id        = var.hosted_zone_id
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  ecs_security_group_id = module.network.ecs_security_group_id
  alb_security_group_id = module.network.alb_security_group_id

  # Container configuration
  container_image     = var.frontend_image
  ecr_repository_name = module.frontend_image_registry.ecr_repository_name
  container_port      = var.frontend_application_port
  health_check_path   = "/"
  container_cpu       = var.frontend_cpu_capacity
  container_memory    = var.frontend_mem_capacity

  # Conditional deployment - only create instances if image is provided
  desired_count = var.frontend_image != "" ? var.frontend_instance_count : 0

  log_retention_days    = 90
  environment_variables = var.frontend_environment_variables

  depends_on = [
    module.network,
    module.frontend_image_registry,
    module.backend_container_service
  ]
}

##############################################################################
# EVENT STREAMING & MONITORING
##############################################################################

# Creates Ambar data sources and destinations for real-time event streaming
# Connects PostgreSQL event store to application endpoints via logical replication
module "ambar" {
  source = "./terraform/ambar"

  data_source_host     = module.event_store.event_store_endpoint
  data_source_user     = module.event_store.event_store_user
  data_source_password = module.event_store.event_store_password
  publication_name     = module.event_store.publication_name

  # Backend application provides authentication credentials for Ambar
  ambar_password = module.backend_container_service.ambar_pw
  ambar_username = module.backend_container_service.ambar_un

  # Only create destinations once backend application is deployed and healthy
  create_destinations = var.backend_image != ""

  data_destination_domain               = local.backend_domain
  destination_endpoints_to_descriptions = var.destination_endpoints_to_descriptions

  depends_on = [
    module.event_store,
    module.projection_store,
    module.backend_container_service
  ]
}

# Creates CloudWatch alarms, SNS topics, and monitoring dashboards
# Provides alerting and observability for all application components
module "monitoring" {
  source = "./terraform/monitoring"

  providers = {
    aws = aws.main
  }

  environment_name        = var.environment_name
  emails_for_alerts       = var.emails_for_alerts
  backend_log_group_name  = module.backend_container_service.cloudwatch_log_group_name
  frontend_log_group_name = module.frontend_container_service.cloudwatch_log_group_name
}