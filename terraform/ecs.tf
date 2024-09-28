# ECS Cluster
resource "aws_ecs_cluster" "service_usuario_cluster" {
  name = "service-usuario-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "service_usuario_task" {
  family                   = "service-usuario-task"
  execution_role_arn       = "arn:aws:iam::496778154277:role/LabRole" 
  container_definitions    = jsonencode([
    {
      name             = "service-usuario-container"
      image            = "${aws_ecr_repository.service_usuario.repository_url}:latest"
      memory           = 512
      cpu              = 256
      essential        = true
      portMappings     = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      environment = [
        {
          name  = "JWT_SECRET"
          value = var.jwt_secret
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"        = "/ecs/service-usuario"
          "awslogs-region"       = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
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
    container_port   = 8081
  }

  depends_on = [
    aws_ecs_cluster.service_usuario_cluster,  # Adiciona dependência explícita do cluster
    aws_lb_target_group.ecs_target_group,     # Garante que o Target Group exista antes do ECS Service
    aws_lb_listener.ecs_lb_listener           # Garante que o Listener esteja configurado
  ]

  tags = {
    Name        = "Service Usuario ECS"
    Environment = "Dev"
  }
}
