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
  authorizer_uri                   = aws_lambda_function.authorizer_lambda.invoke_arn
  authorizer_credentials           = data.aws_iam_role.lambda_role.arn
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
  type                             = "TOKEN"
}

# /cadastrar Resource
resource "aws_api_gateway_resource" "cadastrar" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "cadastrar"
}

# /cadastrar/usuario Resource
resource "aws_api_gateway_resource" "usuario" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.cadastrar.id
  path_part   = "usuario"
}

# POST /cadastrar/usuario
resource "aws_api_gateway_method" "post_usuario" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.usuario.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_integration" "post_usuario_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.usuario.id
  http_method             = aws_api_gateway_method.post_usuario.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.ecs_load_balancer.dns_name}/cadastrar/usuario"
}

# GET /cadastrar/usuario
resource "aws_api_gateway_method" "get_usuario" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.usuario.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_integration" "get_usuario_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.usuario.id
  http_method             = aws_api_gateway_method.get_usuario.http_method
  integration_http_method = "GET"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.ecs_load_balancer.dns_name}/cadastrar/usuario"
}

# GET /cadastrar/usuario/documento/{documento}
resource "aws_api_gateway_resource" "usuario_documento" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.usuario.id
  path_part   = "documento"
}

resource "aws_api_gateway_method" "get_usuario_documento" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.usuario_documento.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_integration" "get_usuario_documento_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.usuario_documento.id
  http_method             = aws_api_gateway_method.get_usuario_documento.http_method
  integration_http_method = "GET"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.ecs_load_balancer.dns_name}/cadastrar/usuario/documento/{documento}"
}

# GET /cadastrar/usuario/crm/{crm}
resource "aws_api_gateway_resource" "usuario_crm" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.usuario.id
  path_part   = "crm"
}

resource "aws_api_gateway_method" "get_usuario_crm" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.usuario_crm.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_integration" "get_usuario_crm_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.usuario_crm.id
  http_method             = aws_api_gateway_method.get_usuario_crm.http_method
  integration_http_method = "GET"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.ecs_load_balancer.dns_name}/cadastrar/usuario/crm/{crm}"
}

# PUT /cadastrar/usuario/{id}
resource "aws_api_gateway_method" "put_usuario" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.usuario.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.api_authorizer.id
}

resource "aws_api_gateway_integration" "put_usuario_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.usuario.id
  http_method             = aws_api_gateway_method.put_usuario.http_method
  integration_http_method = "PUT"
  type                    = "HTTP"
  uri                     = "http://${aws_lb.ecs_load_balancer.dns_name}/cadastrar/usuario/{id}"
}

# /protected Resource
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
  type                    = "MOCK" # Ajuste para HTTP ou AWS_PROXY se necessário
}

# Deployment of the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.login_post_integration,
    aws_api_gateway_integration.protected_get_integration,
    aws_api_gateway_integration.post_usuario_integration,
    aws_api_gateway_integration.get_usuario_integration,
    aws_api_gateway_integration.get_usuario_documento_integration,
    aws_api_gateway_integration.get_usuario_crm_integration,
    aws_api_gateway_integration.put_usuario_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "dev"
}
