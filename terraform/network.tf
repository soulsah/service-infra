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
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "ecs-subnet-1"
    Environment = "Dev"
  }
}

resource "aws_subnet" "ecs_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
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

  # Permitir tráfego HTTP na porta 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir tráfego na porta 8081 (necessário para o ECS Service)
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir todo tráfego de saída
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
