variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "github_organization_with_read_write_access" {
  type = string
}

variable "github_repository_with_read_write_access" {
  type = string
}

variable "github_branch_with_read_write_access" {
  type = string
}

variable "ecr_repo_name" {
  type = string
}