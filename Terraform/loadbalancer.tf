# Application Load Balancer
resource "aws_lb" "Telemetry-ALB-For-ECS-Service" {
  name               = "Telemetry-ALB-For-ECS-Service"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.default_security_group_id]
  subnets            = module.vpc.public_subnets.*
 
  enable_deletion_protection = false
}

# Target group for the tasks
resource "aws_alb_target_group" "TG-For-ECS-Service" {
  name        = "Telemetry-ALB-For-ECS-Service"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
 
  health_check {
   healthy_threshold   = "3"
   interval            = "30"
   protocol            = "HTTP"
   matcher             = "200"
   timeout             = "3"
   path                = "/api"
   unhealthy_threshold = "5"
  }
}

# HTTP listener (for now, HTTPS can be added later)
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.Telemetry-ALB-For-ECS-Service.id
  port              = 80
  protocol          = "HTTP"
 
  default_action {
   type = "forward"
 
   target_group_arn = aws_alb_target_group.TG-For-ECS-Service.arn
  }
}