variable "data_destination_domain" {
  description = "The base domain of the backend service API endpoints"
  type        = string
}

variable "destination_endpoints_to_descriptions" {
  description = "List of destinations objects describing endpoint path and a description"
  type = list(object({
    path        = string
    description = string
  }))
}

variable "ambar_username" {
  description = "Username Ambar should use for HTTP authentication with the backend application"
  type        = string
}

variable "ambar_password" {
  description = "Password Ambar should use for HTTP authentication with the backend application"
  type        = string
  sensitive   = true
}

variable "filter_id" {
  description = "The Ambar resource id for the all events filter"
  type = string
}