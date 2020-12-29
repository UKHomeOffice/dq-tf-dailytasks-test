resource "aws_cloudwatch_event_target" "rds_shutdown" {
  rule = "${aws_cloudwatch_event_rule.rds_shutdown.name}"
  arn  = "${aws_lambda_function.rds_shutdown.arn}"

  input = <<DOC
{
  "instances": [
    "dev-int-tableau-postgres-internal-tableau-apps-test-dq",
    "ext-tableau-postgres-external-tableau-apps-test-dq",
    "fms-postgres-fms-apps-test-dq",
    "mds-rds-mssql2012-dataingest-apps-test-dq",
    "postgres-datafeeds-apps-test-dq"
  ],
  "action": "stop"
}
DOC
}

resource "aws_cloudwatch_event_rule" "rds_shutdown" {
  name                = "rds-shutdown"
  description         = "Shutdown RDS Instances"
  schedule_expression = "cron(05 15 * * ? *)"
  is_enabled          = "false"
}

resource "aws_cloudwatch_event_target" "ec2_shutdown" {
  rule = "${aws_cloudwatch_event_rule.ec2_shutdown.name}"
  arn  = "${aws_lambda_function.ec2_shutdown.arn}"

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
