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