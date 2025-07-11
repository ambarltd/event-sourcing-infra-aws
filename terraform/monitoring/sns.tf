resource "aws_sns_topic" "alerts_topic" {
  name = "event-sourcing-app-alerts"
}

resource "aws_sns_topic_subscription" "alerts_subscription" {
  # Loop
  for_each = toset(var.emails_for_alerts)

  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = each.value
}