locals {
  backend_domain  = var.backend_application_domain_prefix != "" ? "${var.backend_application_domain_prefix}.${var.top_level_domain}" : "api.${var.top_level_domain}"
  frontend_domain = var.frontend_application_domain_prefix != "" ? "${var.frontend_application_domain_prefix}.${var.top_level_domain}" : var.top_level_domain
}

module "email" {
  source = "./terraform/email"

  environment_name       = var.environment_name
  domain_name            = var.top_level_domain
  route53_zone_name      = var.hosted_zone_name
  route53_zone_id        = var.hosted_zone_id
  allowed_from_address   = var.from_email

  providers = {
    aws = aws.main,
    aws.alt_region = aws.alt_region
  }
}

module "network" {
  source = "./terraform/network"

  providers = {
    aws = aws.main
  }

  environment_name = var.environment_name
  region           = var.region

  # gets converted to regiona, regionb, etc. E.G. us-east-1a, us-east-1b...
  # These configs get defaulted to these values, but we are bubbling them up to be explicit / for visibility
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["a", "b", "c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  application_ports = [var.frontend_application_port, var.backend_application_port]
}

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

module "object_storage" {
  source = "./terraform/object_storage"

  providers = {
    aws = aws.main
  }

  environment_name     = var.environment_name
  frontend_cors_domain = var.top_level_domain

  # These configs get defaulted to these values, but we are bubbling them up to be explicit / for visibility
  enable_versioning                  = true
  lifecycle_enabled                  = true
  noncurrent_version_expiration_days = 90
}

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

module "projection_store" {
  source = "./terraform/projection_store"

  environment_name  = var.environment_name
  atlas_project_id  = var.mongodbatlas_project_id
  mongodb_version   = "7.0"
  region            = var.region
  mongodb_free_tier = var.mongodbatlas_free_tier

  depends_on = [module.network]
}

module "ambar" {
  source = "./terraform/ambar"

  data_source_host     = module.event_store.event_store_endpoint
  data_source_user     = module.event_store.event_store_user
  data_source_password = module.event_store.event_store_password
  publication_name     = module.event_store.publication_name

  # Backend Application will create a un + pw for ambar to authenticate using
  ambar_password       = module.backend_container_service.ambar_pw
  ambar_username       = module.backend_container_service.ambar_un

  # Only create the destinations once the backend application is deployed.
  create_destinations = var.backend_image != ""

  data_destination_domain = local.backend_domain

  destination_endpoints_to_descriptions = var.destination_endpoints_to_descriptions

  depends_on = [
    module.event_store,
    module.projection_store,
    module.backend_container_service
  ]
}

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

  container_image     = var.backend_image
  ecr_repository_name = module.backend_image_registry.ecr_repository_name
  container_port      = var.backend_application_port
  health_check_path   = "/"
  container_cpu       = var.backend_cpu_capacity
  container_memory    = var.backend_mem_capacity

  # S3 access
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
  mongodb_port     = 27017 # Not used when the srv string is passed
  mongodb_username = module.projection_store.projection_store_user
  mongodb_password = module.projection_store.projection_store_password

  # SMTP Configuration
  smtp_host       = module.email.smtp_host
  smtp_port       = module.email.smtp_port
  smtp_username   = module.email.smtp_username
  smtp_password   = module.email.smtp_password
  smtp_from_email = var.from_email

  # If no image supplied, then don't create any instances which will anyways just fail.
  desired_count = var.backend_image != "" ? var.backend_instance_count : 0

  log_retention_days = 90

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

  container_image     = var.frontend_image
  ecr_repository_name = module.frontend_image_registry.ecr_repository_name
  container_port      = var.frontend_application_port
  health_check_path   = "/"
  container_cpu       = var.frontend_cpu_capacity
  container_memory    = var.frontend_mem_capacity

  # If no image supplied, then don't create any instances which will anyways just fail.
  desired_count = var.frontend_image != "" ? var.frontend_instance_count : 0

  log_retention_days = 90

  environment_variables = var.frontend_environment_variables

  depends_on = [
    module.network,
    module.frontend_image_registry,
    module.backend_container_service
  ]
}
