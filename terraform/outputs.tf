output "auth_service_lambda_arn" {
  description = "ARN da função Lambda de autenticação"
  value       = aws_lambda_function.auth_service_lambda.arn
}

output "authorizer_lambda_arn" {
  description = "ARN da função Lambda do authorizer"
  value       = aws_lambda_function.authorizer_lambda.arn
}




# ECR Repository URL
output "service_usuario_ecr_url" {
  description = "URL do repositório ECR para Service Usuario"
  value       = aws_ecr_repository.service_usuario.repository_url
}

# VPC ID
output "vpc_id" {
  description = "ID da VPC para ECS"
  value       = aws_vpc.ecs_vpc.id
}

# Subnets
output "subnet_ids" {
  description = "IDs das subnets para ECS"
  value       = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]
}

# Load Balancer DNS
output "ecs_lb_dns" {
  description = "DNS do Load Balancer do ECS"
  value       = aws_lb.ecs_load_balancer.dns_name
}
