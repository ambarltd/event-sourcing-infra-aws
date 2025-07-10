output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.blob_storage.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.blob_storage.arn
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.blob_storage.bucket
}

output "bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.blob_storage.bucket_domain_name
}

output "s3_user_name" {
  description = "The name of the IAM user with access to the S3 bucket"
  value       = aws_iam_user.s3_user.name
}

output "s3_user_arn" {
  description = "The ARN of the IAM user with access to the S3 bucket"
  value       = aws_iam_user.s3_user.arn
}

output "s3_access_key_id" {
  description = "The access key ID for the IAM user"
  value       = aws_iam_access_key.s3_user_key.id
  sensitive   = true
}

output "s3_secret_access_key" {
  description = "The secret access key for the IAM user"
  value       = aws_iam_access_key.s3_user_key.secret
  sensitive   = true
}