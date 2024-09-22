# VPC Configuration
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "ecs-vpc"
    Environment = "Dev"
  }
}

# Subnets for ECS
resource "aws_subnet" "ecs_subnet_1" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "ecs-subnet-1"
    Environment = "Dev"
  }
}

resource "aws_subnet" "ecs_subnet_2" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name        = "ecs-subnet-2"
    Environment = "Dev"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id
  tags = {
    Name        = "ecs-igw"
    Environment = "Dev"
  }
}

# Route Table
resource "aws_route_table" "ecs_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }
  tags = {
    Name        = "ecs-route-table"
    Environment = "Dev"
  }
}

# Route Table Associations
resource "aws_route_table_association" "ecs_rta_1" {
  subnet_id      = aws_subnet.ecs_subnet_1.id
  route_table_id = aws_route_table.ecs_route_table.id
}

resource "aws_route_table_association" "ecs_rta_2" {
  subnet_id      = aws_subnet.ecs_subnet_2.id
  route_table_id = aws_route_table.ecs_route_table.id
}

# Security Group for ECS
resource "aws_security_group" "ecs_security_group" {
  vpc_id = aws_vpc.ecs_vpc.id
  name   = "ecs-security-group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ecs-security-group"
    Environment = "Dev"
  }
}

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

# ECR Repository for Service Usuario
resource "aws_ecr_repository" "service_usuario" {
  name = "service-usuario"
  
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "Service Usuario ECR"
    Environment = "Dev"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "service_usuario_cluster" {
  name = "service-usuario-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "service_usuario_task" {
  family                   = "service-usuario-task"
  execution_role_arn       = data.aws_iam_role.lambda_role.arn
  container_definitions    = jsonencode([
    {
      name             = "service-usuario-container"
      image            = "${aws_ecr_repository.service_usuario.repository_url}:latest"
      memory           = 512
      cpu              = 256
      essential        = true
      portMappings     = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        {
          name  = "JWT_SECRET"
          value = var.jwt_secret
        }
      ]
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "1024"
  cpu                      = "512"
}

# ECS Service
resource "aws_ecs_service" "service_usuario" {
  name            = "service-usuario"
  cluster         = aws_ecs_cluster.service_usuario_cluster.id
  task_definition = aws_ecs_task_definition.service_usuario_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]
    security_groups = [aws_security_group.ecs_security_group.id]
  }

  tags = {
    Name        = "Service Usuario ECS"
    Environment = "Dev"
  }
}
