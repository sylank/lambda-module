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
}

# IAM
resource "aws_iam_role" "lambda_role" {
  name       = "${var.function_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "apigateway.amazonaws.com"
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


resource "aws_iam_policy" "lambda_logging" {
  name = "${var.function_name}"
  path = "/"
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
  role = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${var.function_name}"

  retention_in_days = "${var.retention_in_days}"
}
