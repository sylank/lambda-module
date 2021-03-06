# Lambda
resource "aws_lambda_function" "lambda_function" {
  s3_bucket = "${var.bucket_name}"
  s3_key    = "${var.bucket_key}"

  function_name = "${var.function_name}"
  role          = "${aws_iam_role.lambda_role.arn}"
  handler       = "${var.handler}"
  runtime       = "${var.runtime}"

  source_code_hash = "${var.file_hash}"
  timeout          = "${var.timeout}"
  memory_size      = "${var.memory}"

  reserved_concurrent_executions = "2"

  environment {
    variables = {
      environment_name = "${var.environment_name}"
      EMAIL_SNS_TOPIC_ARN = "${var.sns_topic_arn}"
      TRANSACTIONAL_EMAIL_QUEUE_NAME = "${var.transactional_email_queue_name}"
      APARTMENT_PREFIX = "${var.apartment_prefix}"
      APARTMENT_NAME = "${var.apartment_name}"
    }
  }
}

# IAM
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "apigateway.amazonaws.com",
          "sns.amazonaws.com",
          "sqs.amazonaws.com",
          "dynamodb.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_function.function_name}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_arn}/*/*"
}

resource "aws_lambda_permission" "sqs_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_function.function_name}"
  principal     = "sqs.amazonaws.com"
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "log_${var.function_name}"
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
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

resource "aws_iam_policy" "lambda_sns" {
  name        = "sns_${var.function_name}"
  path        = "/"
  description = "IAM policy for post to sns topic"

  policy = <<EOF
{
    "Version":"2012-10-17",
    "Id":"AWSAccountTopicAccess",
    "Statement" :[
        {
            "Effect":"Allow",           
            "Action":[
                      "sns:Publish",
                      "sns:CreateTopic"
                     ],
            "Resource":"arn:aws:sns:eu-central-1:*:*"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_sns.arn}"
}

resource "aws_iam_policy" "lambda_sqs" {
  name        = "sqs_${var.function_name}"
  path        = "/"
  description = "IAM policy for post to sqs queue"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sqs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_sqs.arn}"
}

resource "aws_iam_policy" "dynamo" {
  name        = "dynamo_${var.function_name}"
  path        = "/"
  description = "IAM policy for dynamo query"

  policy = <<EOF
{
    "Version":"2012-10-17",
    "Id":"AWSAccountTopicAccess",
    "Statement" :[
        {
            "Effect":"Allow",           
            "Action":[
                      "dynamodb:DeleteItem",
                      "dynamodb:GetItem",
                      "dynamodb:PutItem",
                      "dynamodb:Scan",
                      "dynamodb:UpdateItem",
                      "dynamodb:Query",
                      "dynamodb:DescribeStream",
                      "dynamodb:GetRecords",
                      "dynamodb:GetShardIterator",
                      "dynamodb:ListStreams"
                     ],
            "Resource":"arn:aws:dynamodb:eu-central-1:*:table/*"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "dynamo" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.dynamo.arn}"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${var.function_name}"

  retention_in_days = "${var.retention_in_days}"
}
