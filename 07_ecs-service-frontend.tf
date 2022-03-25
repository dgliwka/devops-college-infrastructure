######################################################
#              IAM Role
######################################################
resource "aws_iam_role" "ecs_task_service_role_frontend" {
  name                 = "Cloud9-${var.project}-ecs-task-service-role-frontend"
  assume_role_policy   = data.aws_iam_policy_document.ecs_task_assume_role.json
  permissions_boundary = format("arn:aws:iam::%s:policy/netguru-boundary", data.aws_caller_identity.current.account_id)
}

resource "aws_iam_role_policy_attachment" "ecs_task_service_role_frontend" {
  role       = aws_iam_role.ecs_task_service_role_frontend.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
######################################################
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project}-frontend"
  retention_in_days = 7
  tags              = local.default_tags
}

resource "aws_ecs_task_definition" "frontend" {
  family = "${var.project}-frontend"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  task_role_arn            = aws_iam_role.ecs_task_service_role_frontend.arn
  execution_role_arn       = aws_iam_role.ecs_task_service_role_frontend.arn

  container_definitions = jsonencode(
    [
      {
        name      = "frontend"
        image     = "nginx:latest"
        cpu       = 512
        memory    = 1024
        essential = true

        portMappings = [
          {
            containerPort = 80
            protocol      = "tcp"
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${var.project}-frontend"
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }
    ]
  )

  lifecycle {
    ignore_changes = [
      container_definitions
    ]
  }

  tags = local.default_tags
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project}-frontend"
  cluster         = module.ecs_cluster.ecs_cluster_id
  task_definition = aws_ecs_task_definition.frontend.arn

  launch_type                        = "FARGATE"
  desired_count                      = 1
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    security_groups  = [aws_security_group.alb_to_ecs.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.ecs_alb.target_group_arns[0]
    container_name   = "frontend"
    container_port   = 80
  }


  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }

  tags = local.default_tags
}
