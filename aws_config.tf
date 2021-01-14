resource "aws_config_config_rule" "s3_bucket_versioning_enabled" {
  name = "s3-bucket-versioning-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.configuration_recorder]
}

resource "aws_config_configuration_recorder" "configuration_recorder" {
  name     = "configuration_recorder"
  role_arn = aws_iam_role.aws_config_role.arn
}

resource "aws_iam_role" "aws_config_role" {
  name = "my-awsconfig-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "aws_config_policy" {
  name = "my-awsconfig-policy"
  role = aws_iam_role.aws_config_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "config:Put*",
          "Effect": "Allow",
          "Resource": "*"
      }
  ]
}
POLICY
}
