## Get current region for SMTP host
data "aws_region" "current" {}
#
locals {
  # Use eu-west-1 for SES when in ap-southeast-5 (Jakarta) as SES is not available there
  ses_region = data.aws_region.current.name == "ap-southeast-5" ? "eu-west-1" : data.aws_region.current.name
}
#
## IAM Role for SES Email Sending
#resource "aws_iam_role" "email_user" {
#  name = "${var.environment_name}-ses-email-sender"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Principal = {
#          Service = "ec2.amazonaws.com"
#        }
#      },
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Principal = {
#          Service = "lambda.amazonaws.com"
#        }
#      },
#      {
#        Action = "sts:AssumeRole"
#        Effect = "Allow"
#        Principal = {
#          Service = "ecs-tasks.amazonaws.com"
#        }
#      }
#    ]
#  })
#}
#
## IAM Policy for SES Email Sending
#resource "aws_iam_policy" "email_sender" {
#  name = "${var.environment_name}-ses-email-sender-policy"
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Action = [
#          "ses:SendEmail",
#          "ses:SendRawEmail",
#          "ses:SendTemplatedEmail",
#          "ses:GetSendQuota",
#          "ses:GetSendStatistics",
#          "ses:GetAccountSendingEnabled"
#        ]
#        Resource = "*"
#        Condition = {
#          StringEquals = {
#            "ses:FromAddress" = var.allowed_from_addresses
#          }
#        }
#      }
#    ]
#  })
#
#  tags = {
#    Name = "${var.environment_name}-ses-email-sender-policy"
#  }
#}
#
## Attach policy to role
#resource "aws_iam_role_policy_attachment" "email_sender" {
#  role       = aws_iam_role.email_user.name
#  policy_arn = aws_iam_policy.email_sender.arn
#}
#
## Instance profile for EC2 instances that need to send email
#resource "aws_iam_instance_profile" "email_user" {
#  name = "${var.environment_name}-ses-email-sender-profile"
#  role = aws_iam_role.email_user.name
#
#  tags = {
#    Name = "${var.environment_name}-ses-email-sender-profile"
#  }
#}
#
## IAM User for SMTP credentials
#resource "aws_iam_user" "smtp_user" {
#  name = "${var.environment_name}-smtp-user"
#
#  tags = {
#    Name = "${var.environment_name}-smtp-user"
#  }
#}
#
## Attach the SES policy to the SMTP user
#resource "aws_iam_user_policy_attachment" "smtp_user_policy" {
#  user       = aws_iam_user.smtp_user.name
#  policy_arn = aws_iam_policy.email_sender.arn
#}
#
## Create access key for SMTP user
#resource "aws_iam_access_key" "smtp_user" {
#  user = aws_iam_user.smtp_user.name
#}