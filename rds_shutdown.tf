data "archive_file" "rds_shutdown_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/rds_shutdown.py"
  output_path = "${local.path_module}/lambda/package/rds_shutdown.zip"
}

resource "aws_lambda_function" "rds_shutdown" {
  filename         = "${path.module}/lambda/package/rds_shutdown.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-rds-shutdown"
  role             = "aws_iam_role.rds_shutdown.arn
  handler          = "rds_shutdown.lambda_handler"
  source_code_hash = data.archive_file.rds_shutdown_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "rds-shutdown-${local.naming_suffix}"
  }
}

resource "aws_iam_role" "rds_shutdown" {
  name = "${var.pipeline_name}-${var.namespace}-rds-shutdown"

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
    Name = "rds-shutdown-${local.naming_suffix}"
  }

}

resource "aws_iam_policy" "rds_shutdown" {
  name        = "${var.pipeline_name}-rds-shutdown"
  path        = "/"
  description = "IAM policy for describing rds"

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
        },
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

resource "aws_iam_role_policy_attachment" "rds_shutdown" {
  role       = aws_iam_role.rds_shutdown.name
  policy_arn = aws_iam_policy.rds_shutdown.arn
}

resource "aws_cloudwatch_log_group" "lambda_rds_shutdown" {
  name              = "/aws/lambda/${aws_lambda_function.rds_shutdown.function_name}"
  retention_in_days = 14

  tags = {
    Name = "rds-shutdown-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_rds_shutdown_logging" {
  name        = "${var.pipeline_name}-rds-shutdown-logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
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

resource "aws_iam_role_policy_attachment" "lambda_rds_shutdown_logs" {
  role       = aws_iam_role.rds_shutdown.name
  policy_arn = aws_iam_policy.lambda_rds_shutdown_logging.arn
}
