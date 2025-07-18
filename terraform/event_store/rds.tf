# DB Subnet group using the database subnets from the network module
resource "aws_db_subnet_group" "rds" {
  name       = "${var.environment_name}-rds-subnet-group"
  subnet_ids = var.database_subnet_ids
}

module "database" {
  name    = "${var.environment_name}-postgres"
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.13.0"

  engine         = "aurora-postgresql"

  engine_version = "15.10"
  # If set to true then AWS will automatically update the minor version (E.G. 15.11) and terraform plan / apply may show
  # changes and error out attempting to downgrade to the listed version.
  auto_minor_version_upgrade = false

  instance_class = "db.t4g.medium"
  instances = {
    one = {
      instance_class      = "db.t4g.medium"
      publicly_accessible = true
    }
    two = {
      instance_class      = "db.t4g.medium"
      publicly_accessible = true
    }
    three = {
      instance_class      = "db.t4g.medium"
      publicly_accessible = true
    }
  }
  vpc_id                 = var.vpc_id
  create_db_subnet_group = false
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  subnets                = var.database_subnet_ids
  storage_encrypted      = true
  apply_immediately      = true

  # Allow public connections. This is required for external services such as Ambar to be able to read the store
  security_group_rules = {
    ex1_ingress = {
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  db_parameter_group_name         = aws_db_parameter_group.postgres.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgres.name

  master_username                      = random_string.db_user.result
  # With password rotation enabled, we will need to ensure any other connections to the database are also rotated, and
  # we would need a mechanism to detect the rotation and update all consuming resources accordingly.
  manage_master_user_password_rotation = false
  manage_master_user_password          = false
  master_password = random_password.db_pass.result

  skip_final_snapshot = true
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${var.environment_name}-db-par-service-postgres"
  family      = "aurora-postgresql15"
  description = "aurora-db-parameter-group"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "postgres" {
  name        = "${var.environment_name}-par-service-postgres"
  family      = "aurora-postgresql15"
  description = "aurora-cluster-parameter-group"

  # this sets the wal_level
  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }
  parameter {
    name         = "wal_sender_timeout"
    value        = "0"
    apply_method = "pending-reboot"
  }

  # Additional parameters for replication
  parameter {
    name         = "max_wal_senders"
    value        = "10"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "max_replication_slots"
    value        = "10"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }
}