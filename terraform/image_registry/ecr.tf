resource "aws_ecr_repository" "repository" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "managed_by" : "terraform"
  }
}

resource "aws_ecr_repository_policy" "repository_policy" {
  repository = aws_ecr_repository.repository.name
  policy     = data.aws_iam_policy_document.repository_policy_document.json
}

data "aws_iam_policy_document" "repository_policy_document" {
  statement {
    sid    = "ReadSubset"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.github.arn]
    }
  }

  statement {
    sid    = "WriteSubset"
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.github.arn]
    }
  }
}