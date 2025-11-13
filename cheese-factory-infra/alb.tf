# Application Load Balancer público para The Cheese Factory
resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = local.common_tags
}

# Target Group HTTP para las instancias web
resource "aws_lb_target_group" "web" {
  name        = "${local.name_prefix}-tg-web"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/"
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = local.common_tags
}

# Listener HTTP en el puerto 80 del ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}


