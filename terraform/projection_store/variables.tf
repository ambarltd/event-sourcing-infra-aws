variable "atlas_project_id" {
  description = "MongoDB Atlas project ID"
  type        = string
}

variable "region" {
  description = "AWS region to use for MongoDB Atlast, will be converted to Atlas region"
  type        = string
}

variable "mongodb_version" {
  description = "MongoDB major version"
  type        = string
}

variable "mongodb_free_tier" {
  description = "MongoDB instance size (AWS): [M0, M10, M40]"
  type = bool
  default = false
}