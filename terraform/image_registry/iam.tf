resource "aws_iam_role" "github" {
  name               = "gha_oidc.${var.ecr_repo_name}.read_write"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
      type        = "Federated"
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test = "StringLike"
      values = [
        "repo:${var.github_organization_with_read_write_access}/${var.github_repository_with_read_write_access}:ref:refs/heads/${var.github_branch_with_read_write_access}"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }
    condition {
      test = "StringLike"
      values = [
        "sts.amazonaws.com"
      ]
      variable = "token.actions.githubusercontent.com:aud"
    }
  }
}

resource "aws_iam_role_policy" "github" {
  name = "gha_oidc.${var.ecr_repo_name}.read_write"
  role = aws_iam_role.github.name

  policy = data.aws_iam_policy_document.github.json
}

data "aws_iam_policy_document" "github" {
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

    resources = ["*"]
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

    resources = ["*"]
  }
}