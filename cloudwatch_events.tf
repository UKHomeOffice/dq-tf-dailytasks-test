resource "aws_cloudwatch_event_target" "ec2_shutdown" {
  rule = aws_cloudwatch_event_rule.ec2_shutdown.name
  arn  = aws_lambda_function.ec2_shutdown.arn

  input = <<DOC
  {
    "Name" : "running"
  }
DOC
}

resource "aws_cloudwatch_event_rule" "ec2_shutdown" {
  name                = "daily_ec2_shutdown"
  description         = "Shutdown EC2 Instances in notprod evenings and weekends"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
  is_enabled          = "true"
}
