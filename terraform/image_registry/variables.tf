# The following three variables must be used together (e.g., other repositories inside the organization won't have access)
variable "github_organization_with_read_write_access" {
  type = string
}

variable "github_repository_with_read_write_access" {
  type = string
}

variable "github_branch_with_read_write_access" {
  type    = string
  default = "main"
}

variable "ecr_repo_name" {
  type = string
}