# outputs.tf

output "auth_service_lambda_arn" {
  description = "ARN da função Lambda de autenticação"
  value       = aws_lambda_function.auth_service_lambda.arn
}

output "authorizer_lambda_arn" {
  description = "ARN da função Lambda do authorizer"
  value       = aws_lambda_function.authorizer_lambda.arn
}

output "api_endpoint" {
  description = "Endpoint da API Gateway"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}"
}
