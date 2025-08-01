variable "environment_name" {
  description = "Environment name used as a prefix for all resources"
  type        = string
}

variable "github_organization_with_read_write_access" {
  description = "GitHub organization name that has access to this ECR repository"
  type = string
}

variable "github_repository_with_read_write_access" {
  description = "GitHub repository name that has access to this ECR repository"
  type = string
}

variable "github_branch_with_read_write_access" {
  description = "GitHub branch name that has access to this ECR repository"
  type = string
}

variable "ecr_repo_name" {
  description = "Name of the ECR repository to create"
  type = string
}