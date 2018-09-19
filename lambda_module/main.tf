# Lambda
resource "aws_lambda_function" "lambda_function" {
  s3_bucket = "${var.bucket_name}"
  s3_key    = "${var.bucket_key}"

  function_name = "${var.function_name}"
  role          = "${aws_iam_role.role.arn}"
  handler       = "${var.handler}"
  runtime       = "${var.runtime}"

  source_code_hash = "${var.file_hash}"
  timeout          = "${var.timeout}"
  memory_size      = "${var.memory}"
}

# IAM
resource "aws_iam_role" "lambda_role" {
  depends_on = ["aws_lambda_function.lambda_function"]
  name       = "${aws_lambda_function.lambda_function.function_name}_lambda_iam_role"

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
