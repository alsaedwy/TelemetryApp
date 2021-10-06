# ECS Cluster - Fargate
resource "aws_ecs_cluster" "Telemetry_Cluster" {
  name = "Telemetry_Cluster"

  configuration {
    execute_command_configuration {
      
      logging    = "OVERRIDE"

      log_configuration {
      #  cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ECS_Telemetry_Logging.name
      }
    }
  }
}

# Task Definition
resource "aws_ecs_task_definition" "TaskDefinition-Telemetry" {
  family = "TelemetryTaskDefinition"
  execution_role_arn = aws_iam_role.TaskDefinition-Telemetry-Execution-Role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  task_role_arn = aws_iam_role.TaskDefinition-Telemetry-Execution-Role.arn
  container_definitions = jsonencode([
    {
      name      = "TelemetryApp"
      image     = "${aws_ecr_repository.TelemetryAppECRRepo.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}


# ECS Service
resource "aws_ecs_service" "TelemetryECSService" {
  name    = "TelemetryECSService"
  cluster = aws_ecs_cluster.Telemetry_Cluster.id
  launch_type = "FARGATE"
  desired_count = 2

  task_definition = aws_ecs_task_definition.TaskDefinition-Telemetry.arn
  network_configuration {
    subnets = [module.vpc.public_subnets[0],module.vpc.public_subnets[1],module.vpc.public_subnets[2]]
    security_groups = [module.vpc.default_security_group_id]
    assign_public_ip = "true"

  }
    load_balancer {
    target_group_arn = aws_alb_target_group.TG-For-ECS-Service.arn
    container_name   = "TelemetryApp"
    container_port   = 80
  }
}
