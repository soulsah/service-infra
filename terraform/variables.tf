# variables.tf

variable "jwt_secret" {
  description = "Chave secreta para assinar o JWT"
  type        = string
  default     = "postech70"
}

variable "ecr_image" {
  description = "Nome da imagem ECR para o Service Usuario"
  type        = string
  default     = "service-usuario:latest"
}

