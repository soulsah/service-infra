# ecs.tf

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
      image            = "496778154277.dkr.ecr.us-east-1.amazonaws.com/service-usuario:latest"
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
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "service-usuario-container"
    container_port   = 80
  }

  depends_on = [
    aws_ecs_cluster.service_usuario_cluster  # Adiciona dependência explícita do cluster
  ]

  tags = {
    Name        = "Service Usuario ECS"
    Environment = "Dev"
  }
}
