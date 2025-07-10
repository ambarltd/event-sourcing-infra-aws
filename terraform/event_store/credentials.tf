resource "random_string" "db_user" {
  length  = 8
  special = false
  upper   = true
  lower   = true
  # PostgreSQL will reject if the user starts with a number
  # so disallow to prevent deployment failures, however unlikely.
  numeric = false
}

resource "random_password" "db_pass" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true

  # Exclude characters that can cause issues in PostgreSQL or connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}