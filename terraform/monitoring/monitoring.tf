# Backend monitoring
resource "aws_cloudwatch_log_metric_filter" "backend_log_filter" {
  name           = "${var.environment_name}-backend-service-log-filter"
  pattern        = "?\"ERROR\" ?\"error\" ?\"Error\""
  log_group_name = var.backend_log_group_name
  metric_transformation {
    name      = "backend-errors"
    namespace = "backend"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_errors_alarm" {
  alarm_name = "${var.environment_name}-backend-errors"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 10
  metric_name         = "backend-errors"
  namespace           = "backend"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"

  actions_enabled = true
  alarm_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sns_topic.alerts_topic.name}"
  ]
}

# Frontend
resource "aws_cloudwatch_log_metric_filter" "frontend_log_filter" {
  name           = "${var.environment_name}-frontend-service-log-filter"
  pattern        = "?\"ERROR\" ?\"error\" ?\"Error\""
  log_group_name = var.frontend_log_group_name
  metric_transformation {
    name      = "frontend-errors"
    namespace = "frontend"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "frontend_errors_alarm" {
  alarm_name = "${var.environment_name}-frontend-errors"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 10
  metric_name         = "frontend-errors"
  namespace           = "frontend"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"

  actions_enabled = true
  alarm_actions = [
    "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sns_topic.alerts_topic.name}"
  ]
}