# RDS Daily shutdown script

### Archive file - rds_shutdown lambda
data "archive_file" "rds_shutdownzip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/rds_shutdown.py"
  output_path = "${local.path_module}/lambda/package/rds_shutdown.zip"
}

### Lambda Functions

resource "aws_lambda_function" "rds_shutdown_function" {
  function_name    = "rds-shutdown-${var.naming_suffix}"
  handler          = "rds_shutdown.lambda_handler"
  runtime          = "python3.7"
  role             = "${aws_iam_role.rds_shutdown_role.arn}"
  filename         = "${data.archive_file.rds_shutdownzip.output_path}"
  memory_size      = 128
  timeout          = "900"
  source_code_hash = "${data.archive_file.rds_shutdownzip.output_base64sha256}"

  tags = {
    Name = "rds-shutdown-${local.naming_suffix}"
  }
}

### IAM role

resource "aws_iam_role" "rds_shutdown_role" {
  name = "rds-shutdown-role-${var.naming_suffix}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "rds-shutdown-role-${local.naming_suffix}"
  }
}

### IAM Policy Documents

# data "aws_iam_policy_document" "eventwatch_logs_doc" {
#   statement {
#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:DescribeLogStreams",
#       "logs:GetLogEvents"
#     ]
#     resources = [
#       "arn:aws:logs:*:*:*",
#     ]
#   }
# }

# data "aws_iam_policy_document" "eventwatch_rds_doc" {
#   statement {
#     actions = [
#       "rds:DescribeDBInstances",
#       "rds:StartDBInstances",
#       "rds:StopDBInstances",
#       "rds:CopyDBSnapshot",
#       "rds:CreateDBSnapshot",
#       "rds:DeleteDBSnapshot"
#     ]
#     resources = [
#       "*"
#     ]
#   }
# }

### IAM Policies

resource "aws_iam_policy" "rds_shutdown" {
  name        = "${var.pipeline_name}-rds-shutdown"
  path        = "/"
  description = "IAM policy for shutting down rds"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
              "rds:*",
              "cloudwatch:GetMetricStatistics",
              "logs:DescribeLogStreams",
              "logs:GetLogEvents"
            ],
            "Resource": "*"
        },
        {
          "Action": "pi:*",
          "Effect": "Allow",
          "Resource": "arn:aws:pi:*:*:metrics/rds/*"
        }
        {
          "Action": "iam:CreateServiceLinkedRole",
          "Effect": "Allow",
          "Resource": "*",
          "Condition": {
            "StringLike": {
              "iam:AWSServiceName": [
                "rds.amazonaws.com"
              ]
            }
          }

        }
    ]
}
EOF
}

# resource "aws_iam_policy" "eventwatch_rds_policy" {
#   name   = "eventwatch-rds-policy"
#   path   = "/"
#   policy = "${data.aws_iam_policy_document.eventwatch_rds_doc.json}"
# }

### IAM Policy Attachments

resource "aws_iam_role_policy_attachment" "rds_shutdown" {
  role       = "${aws_iam_role.rds_shutdown_role.name}"
  policy_arn = "${aws_iam_policy.rds_shutdown.arn}"
}

resource "aws_iam_role_policy_attachment" "lambda_rds_shutdown_logging" {
  role       = "${aws_iam_role.rds_shutdown_role.name}"
  policy_arn = "${aws_iam_policy.lambda_rds_shutdown_logging.arn}"
}

# Creates CloudWatch Log Group

resource "aws_cloudwatch_log_group" "lambda_rds_shutdown" {
  name              = "/aws/lambda/${aws_lambda_function.rds_shutdown_function.function_name}"
  retention_in_days = 14

  tags = {
    Name = "rds-shutdown-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_rds_shutdown_logging" {
  name        = "${var.pipeline_name}-rds_shutdown-logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.lambda_rds_shutdown.arn}",
        "${aws_cloudwatch_log_group.lambda_rds_shutdown.arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Creates CloudWatch Event Rule - triggers the Lambda function

resource "aws_cloudwatch_event_rule" "daily_rds_shutdown" {
  is_enabled          = "true"
  name                = "daily-rds-shutdown"
  description         = "triggers daily RDS shutdown"
  schedule_expression = "cron(30 12 * * ? *)"
}

# Defines target for the rule - the Lambda function to trigger
# Points to the Lamda function

resource "aws_cloudwatch_event_target" "rds_lambda_target" {
  target_id = "rds-shutdown-function"
  rule      = "${aws_cloudwatch_event_rule.daily_rds_shutdown.name}"
  arn       = "${aws_lambda_function.rds_shutdown_function.arn}"
}
