# ecr.tf

# Repositório ECR para Service Usuario
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
