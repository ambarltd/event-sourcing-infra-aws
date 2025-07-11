resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "blob_storage" {
  bucket = "blob-storage-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_cors_configuration" "cors_configuration" {
  bucket = aws_s3_bucket.blob_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET", "HEAD"]
    allowed_origins = ["https://${var.frontend_cors_domain}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_versioning" "blob_storage_versioning" {
  bucket = aws_s3_bucket.blob_storage.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "blob_storage_encryption" {
  bucket = aws_s3_bucket.blob_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "blob_storage_lifecycle" {
  bucket = aws_s3_bucket.blob_storage.id

  rule {
    id     = "cleanup-old-versions"
    status = var.lifecycle_enabled ? "Enabled" : "Disabled"

    filter {
      prefix = "" # Empty prefix applies to all objects in the bucket
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "blob_storage_public_access" {
  bucket = aws_s3_bucket.blob_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM User for S3 bucket access
resource "aws_iam_user" "s3_user" {
  name = "s3-user"
  path = "/system/"

  tags = {
    Name    = "s3-user"
  }
}

# Generate access keys for the IAM user
resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}

# Create IAM policy document for S3 access
data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      "*"
    ]
  }

}

# Create the IAM policy
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "Policy for accessing the blob storage bucket"
  policy      = data.aws_iam_policy_document.s3_access.json
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "s3_user_policy_attachment" {
  user       = aws_iam_user.s3_user.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}