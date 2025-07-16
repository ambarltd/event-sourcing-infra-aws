locals {
  # Helper local, add more regions as needed.
  # https://www.mongodb.com/docs/atlas/reference/amazon-aws/
  aws_to_atlast_region = {
    # North America
    "us-east-1"    : "US_EAST_1",
    "us-east-2"    : "US_EAST_2",
    "us-west-1"    : "US_WEST_1",
    "us-west-2"    : "US_WEST_2",
    "ca-central-1" : "CA_CENTRAL_1",
    "ca-west-1"    : "CA_WEST_1",
    "mx-central-1" : "MX_CENTRAL_1",

    # South America
    "sa-east-1" : "SA_EAST_1",

    # Europe
    "eu-central-1" : "EU_CENTRAL_1",
    "eu-central-2" : "EU_CENTRAL_2",
    "eu-west-1"    : "EU_WEST_1",
    "eu-west-2"    : "EU_WEST_2",
    "eu-west-3"    : "EU_WEST_3",
    "eu-north-1"   : "EU_NORTH_1",
    "eu-south-1"   : "EU_SOUTH_1",
    "eu-south-2"   : "EU_SOUTH_2",

    # Asia Pacific
    "ap-northeast-1" : "AP_NORTHEAST_1",
    "ap-northeast-2" : "AP_NORTHEAST_2",
    "ap-northeast-3" : "AP_NORTHEAST_3",
    "ap-south-1"     : "AP_SOUTH_1",
    "ap-south-2"     : "AP_SOUTH_2",
    "ap-southeast-1" : "AP_SOUTHEAST_1",
    "ap-southeast-2" : "AP_SOUTHEAST_2",
    "ap-southeast-3" : "AP_SOUTHEAST_3",
    "ap-southeast-4" : "AP_SOUTHEAST_4",
    "ap-southeast-5" : "AP_SOUTHEAST_5",
    "ap-southeast-7" : "AP_SOUTHEAST_7",
    "ap-east-1"      : "AP_EAST_1",

    # Middle East
    "me-south-1"   : "ME_SOUTH_1",
    "me-central-1" : "ME_CENTRAL_1",
    "il-central-1" : "IL_CENTRAL_1",

    # Africa
    "af-south-1" : "AF_SOUTH_1"
  }
}

# MongoDB Atlas Cluster
resource "mongodbatlas_cluster" "projection_store" {
  count = !var.mongodb_free_tier ? 1 : 0

  project_id   = var.atlas_project_id
  name         = "projection-store"
  cluster_type = "REPLICASET"

  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = local.aws_to_atlast_region[var.region]
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }

  cloud_backup                 = true
  auto_scaling_disk_gb_enabled = true
  mongo_db_major_version       = var.mongodb_version

  provider_name               = "AWS"
  provider_instance_size_name = "M10"

  termination_protection_enabled = true

  lifecycle {
    ignore_changes = [
      provider_instance_size_name
    ]
  }
}

resource "mongodbatlas_cluster" "free_projection_store" {
  count = var.mongodb_free_tier ? 1 : 0

  name                        = "projection-store"
  project_id                  = var.atlas_project_id
  provider_instance_size_name = "M0"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
}

# IP whitelist
resource "mongodbatlas_project_ip_access_list" "aws_access" {
  project_id = var.atlas_project_id
  cidr_block = "0.0.0.0/0"
  comment    = "CIDR block for public access"
}

# Backup policy
resource "mongodbatlas_cloud_backup_schedule" "backup_schedule" {
  project_id   = var.atlas_project_id
  cluster_name = var.mongodb_free_tier ? mongodbatlas_cluster.free_projection_store[0].name : mongodbatlas_cluster.projection_store[0].name

  reference_hour_of_day    = 3
  reference_minute_of_hour = 0

  # Daily backup policy retaining 7 days of backups
  policy_item_daily {
    frequency_interval = 1
    retention_unit     = "days"
    retention_value    = 7
  }
}