variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where to create the RDS instance"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of IDs of database subnets"
  type        = list(string)
}