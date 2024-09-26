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
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.ecs_nlb.dns_name}/auth/login"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.api_gateway_vpc_link.id
}

# Criar VPC Link para o API Gateway (usando target_arns)
resource "aws_api_gateway_vpc_link" "api_gateway_vpc_link" {
  name = "api-gateway-vpc-link"
  target_arns = [aws_lb.ecs_nlb.arn]  # Lista de ARNs do NLB
}
