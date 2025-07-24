# IAM Policy for SES Email Sending
resource "aws_iam_user" "smtp_user" {
  provider       = aws.alt_region

  name = "${var.environment_name}-smtp-user"
}

resource "aws_iam_access_key" "smtp_user" {
  provider       = aws.alt_region

  user = aws_iam_user.smtp_user.name
}

data "aws_iam_policy_document" "ses_sender" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses_sender" {
  provider       = aws.alt_region

  name        = "ses_sender"
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.ses_sender.json
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  provider       = aws.alt_region

  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_sender.arn
}