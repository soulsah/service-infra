# main.tf


# DynamoDB Tables Configuration

resource "aws_dynamodb_table" "cliente" {
  name         = "Cliente"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Cliente Table"
    Environment = "Dev"
  }
}

resource "aws_dynamodb_table" "agendarConsulta" {
  name         = "agendarConsulta"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Agendar Consulta Table"
    Environment = "Dev"
  }
}

resource "aws_dynamodb_table" "horariosAtendimento" {
  name         = "horariosAtendimento"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "documentoMedico"
  range_key    = "horarioInicio"

  attribute {
    name = "documentoMedico"
    type = "S"
  }

  attribute {
    name = "horarioInicio"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Horarios Atendimento Table"
    Environment = "Dev"
  }
}

# Lambda Functions and API Gateway Configuration

# Package the Lambda functions
data "archive_file" "auth_service_lambda_zip" {
  type        = "zip"
  source_dir  = "../lambdas/auth_service_lambda_package"
  output_path = "../lambdas/auth_service_lambda.zip"
}

data "archive_file" "authorizer_lambda_zip" {
  type        = "zip"
  source_dir  = "../lambdas/authorizer_lambda_package"
  output_path = "../lambdas/authorizer_lambda.zip"
}

# Reference to Existing IAM Role
data "aws_iam_role" "lambda_role" {
  name = "LabRole"
}

# Auth Service Lambda Function
resource "aws_lambda_function" "auth_service_lambda" {
  filename         = data.archive_file.auth_service_lambda_zip.output_path
  function_name    = "auth-service-lambda"
  role             = data.aws_iam_role.lambda_role.arn  # Reference to existing role
  handler          = "auth_service_lambda.lambda_handler"
  source_code_hash = data.archive_file.auth_service_lambda_zip.output_base64sha256
  runtime          = "python3.8"
  timeout          = 30

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }

  # Remove depends_on since we can't manage policies for an external role
}

# Authorizer Lambda Function
resource "aws_lambda_function" "authorizer_lambda" {
  filename         = data.archive_file.authorizer_lambda_zip.output_path
  function_name    = "authorizer-lambda"
  role             = data.aws_iam_role.lambda_role.arn  # Reference to existing role
  handler          = "authorizer_lambda.lambda_handler"
  source_code_hash = data.archive_file.authorizer_lambda_zip.output_base64sha256
  runtime          = "python3.8"
  timeout          = 5

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }

  # Remove depends_on since we can't manage policies for an external role
}

# API Gateway Configuration

resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "MyAPIGateway"
}

# /auth Resource
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "auth"
}

# /auth/login Resource
resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

# POST Method for /auth/login
resource "aws_api_gateway_method" "login_post" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.login.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration for /auth/login POST Method
resource "aws_api_gateway_integration" "login_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.login.id
  http_method             = aws_api_gateway_method.login_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth_service_lambda.invoke_arn
}

# Lambda Permission for API Gateway to Invoke Auth Service Lambda
resource "aws_lambda_permission" "allow_api_gateway_invoke_auth" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_service_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}

# Authorizer Configuration
resource "aws_api_gateway_authorizer" "api_authorizer" {
  name                             = "JWTAuthorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api_gateway.id
  authorizer_uri                   = "${aws_lambda_function.authorizer_lambda.invoke_arn}"
  authorizer_credentials           = data.aws_iam_role.lambda_role.arn  # Reference to existing role
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
  type                             = "TOKEN"
}

# Protected Resource: /protected
resource "aws_api_gateway_resource" "protected_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "protected"
}

# GET Method for /protected
resource "aws_api_gateway_method" "protected_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.protected_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

# Integration for /protected GET Method
resource "aws_api_gateway_integration" "protected_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.protected_resource.id
  http_method             = aws_api_gateway_method.protected_get.http_method
  integration_http_method = "GET"
  type                    = "MOCK"
}

# Deployment of the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.login_post_integration,
    aws_api_gateway_integration.protected_get_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "dev"
}
