resource "aws_cloudwatch_log_group" "cb_log_group" {
  name              = "/ecs/${var.app_prefix}"
  retention_in_days = 30

  tags = {
    Name = "notejam-log-group"
  }
}

resource "aws_cloudwatch_log_stream" "cb_log_stream" {
  name           = "${var.app_prefix}-log-stream"
  log_group_name = aws_cloudwatch_log_group.cb_log_group.name
}
