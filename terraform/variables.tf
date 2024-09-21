# variables.tf

variable "jwt_secret" {
  description = "Chave secreta para assinar o JWT"
  type        = string
  default     = "postech70"
}
