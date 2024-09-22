# dynamodb.tf

# Tabela Cliente
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

# Tabela Agendar Consulta
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

# Tabela Horarios Atendimento
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
