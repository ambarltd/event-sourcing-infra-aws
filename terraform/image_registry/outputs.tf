output "ecr_repository_name" {
  value = aws_ecr_repository.repository.name
}

output "ecr_repository_repository_url" {
  value = aws_ecr_repository.repository.repository_url
}

output "github_assumable_role_read_write" {
  value = aws_iam_role.github.arn
}