terraform {
  backend "s3" {
    # https://developer.hashicorp.com/terraform/language/settings/backends/configuration#partial-configuration
    # https://discuss.hashicorp.com/t/error-invalid-aws-region-ap-southeast-4/49985/2
    skip_region_validation = true
  }
}