resource "random_string" "ambar_user" {
  length  = 8
  special = false
  upper   = true
}

resource "random_password" "ambar_pass" {
  length = 16
}