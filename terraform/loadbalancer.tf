# Criar Load Balancer
resource "aws_lb" "ecs_load_balancer" {
  name               = "ecs-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]

  tags = {
    Name        = "ecs-load-balancer"
    Environment = "Dev"
  }
}

# Criar Target Group
resource "aws_lb_target_group" "service_usuario_tg" {
  name        = "ecs-target-group"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    path                = "/actuator/health"  # Ajuste para a rota de health do Spring Boot
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "ecs-target-group"
    Environment = "Dev"
  }
}

# Criar Network Load Balancer (NLB) ao invés de Application Load Balancer (ALB)
resource "aws_lb" "ecs_nlb" {
  name               = "ecs-network-load-balancer"
  internal           = false
  load_balancer_type = "network"  # Tipo deve ser "network" para NLB
  subnets            = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]

  tags = {
    Name        = "ecs-network-load-balancer"
    Environment = "Dev"
  }
}


# Criar Listener para o Load Balancer
resource "aws_lb_listener" "service_usuario_listener" {
  load_balancer_arn = aws_lb.ecs_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_usuario_tg.arn
  }
}
