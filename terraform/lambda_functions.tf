# Definir o IAM Role para Lambda Functions
data "aws_iam_role" "lambda_role" {
  name = "LabRole"
}

# Auth Service Lambda Function
resource "aws_lambda_function" "auth_service_lambda" {
  filename         = "../lambdas/auth_service_lambda.zip"
  function_name    = "auth-service-lambda"
  role             = data.aws_iam_role.lambda_role.arn
  handler          = "auth_service_lambda.lambda_handler"
  source_code_hash = filebase64sha256("../lambdas/auth_service_lambda.zip")
  runtime          = "python3.8"
  timeout          = 30

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }
}

# Authorizer Lambda Function
resource "aws_lambda_function" "authorizer_lambda" {
  filename         = "../lambdas/authorizer_lambda.zip"
  function_name    = "authorizer-lambda"
  role             = data.aws_iam_role.lambda_role.arn
  handler          = "authorizer_lambda.lambda_handler"
  source_code_hash = filebase64sha256("../lambdas/authorizer_lambda.zip")
  runtime          = "python3.8"
  timeout          = 5

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }
}
