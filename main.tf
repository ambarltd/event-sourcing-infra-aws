# Domain Module
module "domain" {
  source = "./terraform/domain"

  domain_name = var.domain
}

# Email Module
module "email" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/email"

  domain_name            = var.domain
  route53_zone_name      = module.domain.zone_name
  route53_zone_id        = module.domain.hosted_zone_id
  allowed_from_addresses = [var.from_email]

  depends_on = [module.domain]
}

# Network Module
module "network" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/network"
  region = var.region

  # gets converted to regiona, regionb, etc. E.G. us-east-1a, us-east-1b...
  # These configs get defaulted to these values, but we are bubbling them up to be explicit / for visibility
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["a", "b", "c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  application_ports = [var.frontend_application_port, var.backend_application_port]
}

# Event Store Module
module "event_store" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/event_store"

  vpc_id              = module.network[0].vpc_id
  database_subnet_ids = module.network[0].public_subnet_ids

  depends_on = [module.network]
}

# Blob Storage Module
module "object_storage" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/object_storage"

  frontend_cors_domain = var.domain

  # These configs get defaulted to these values, but we are bubbling them up to be explicit / for visibility
  enable_versioning                  = true
  lifecycle_enabled                  = true
  noncurrent_version_expiration_days = 90
}

# Image Registry Modules
module "backend_image_registry" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/image_registry"

  ecr_repo_name                              = "event-sourcing-app-backend"
}

module "frontend_image_registry" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/image_registry"

  ecr_repo_name                              = "event-sourcing-app-frontend"
}

module "projection_store" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/projection_store"

  atlas_project_id  = var.mongodbatlas_project_id
  mongodb_version   = "7.0"
  region            = var.region
  mongodb_free_tier = var.mongodbatlas_free_tier

  depends_on = [module.network]
}

module "ambar" {
  count  = (var.nameserver_records_completed && var.event_store_configured) ? 1 : 0
  source = "./terraform/ambar"

  data_source_host     = module.event_store[0].event_store_endpoint
  data_source_user     = module.event_store[0].event_store_user
  data_source_password = module.event_store[0].event_store_password
  ambar_password       = module.backend_container_service[0].ambar_un
  ambar_username       = module.backend_container_service[0].ambar_pw

  data_destination_domain = var.backend_application_domain

  destination_endpoints_to_descriptions = var.destination_endpoints_to_descriptions

  depends_on = [
    module.event_store,
    module.projection_store,
    module.backend_container_service
  ]
}

module "backend_container_service" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/backend_service"

  region                = var.region
  backend_domain        = "api.${var.domain}"
  frontend_domain       = var.domain
  hosted_zone_id        = module.domain.hosted_zone_id
  vpc_id                = module.network[0].vpc_id
  public_subnet_ids     = module.network[0].public_subnet_ids
  private_subnet_ids    = module.network[0].private_subnet_ids
  ecs_security_group_id = module.network[0].ecs_security_group_id

  container_image     = var.backend_image
  ecr_repository_name = module.backend_image_registry[0].ecr_repository_name
  container_port      = var.backend_application_port
  health_check_path   = "/"
  container_cpu       = var.backend_cpu_capacity
  container_memory    = var.backend_mem_capacity

  # S3 access
  blob_storage_bucket_name = module.object_storage[0].bucket_name
  blob_storage_bucket_arn  = module.object_storage[0].bucket_arn
  s3_access_key_id         = module.object_storage[0].s3_access_key_id
  s3_secret_access_key     = module.object_storage[0].s3_secret_access_key

  # Event Store Configuration
  event_store_endpoint = module.event_store[0].event_store_endpoint
  event_store_port     = 5432
  event_store_username = module.event_store[0].event_store_user
  event_store_password = module.event_store[0].event_store_password

  # MongoDB Projection Store Configuration
  mongodb_host     = module.projection_store[0].srv_connection_host
  mongodb_port     = 27017 # Not used when the srv string is passed
  mongodb_username = module.projection_store[0].projection_store_user
  mongodb_password = module.projection_store[0].projection_store_password

  # SMTP Configuration
  smtp_host       = module.email[0].smtp_host
  smtp_port       = module.email[0].smtp_port
  smtp_username   = module.email[0].smtp_username
  smtp_password   = module.email[0].smtp_password
  smtp_from_email = var.from_email

  desired_count = var.backend_instance_count

  # Monitoring
  log_retention_days = 90

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
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/monitoring"

  emails_for_alerts      = var.emails_for_alerts
  backend_log_group_name = module.backend_container_service[0].cloudwatch_log_group_name
}

module "frontend_container_service" {
  count  = var.nameserver_records_completed ? 1 : 0
  source = "./terraform/frontend_service"

  region                = var.region
  backend_endpoint      = module.backend_container_service[0].nlb_dns_name
  frontend_domain       = var.domain
  additional_domains    = var.additional_frontend_domains
  hosted_zone_id        = module.domain.hosted_zone_id
  vpc_id                = module.network[0].vpc_id
  public_subnet_ids     = module.network[0].public_subnet_ids
  private_subnet_ids    = module.network[0].private_subnet_ids
  ecs_security_group_id = module.network[0].ecs_security_group_id
  alb_security_group_id = module.network[0].alb_security_group_id

  container_image     = var.frontend_image
  ecr_repository_name = module.frontend_image_registry[0].ecr_repository_name
  container_port      = var.frontend_application_port
  health_check_path   = "/"
  container_cpu       = var.frontend_cpu_capacity
  container_memory    = var.frontend_mem_capacity

  desired_count = var.frontend_instance_count

  # Monitoring
  log_retention_days = 90

  depends_on = [
    module.network,
    module.frontend_image_registry,
    module.backend_container_service
  ]
}

