locals {
  database_url = "postgresql://${module.db.db_instance_username}:${module.db.db_master_password}@${module.db.db_instance_address}:${module.db.db_instance_port}/${module.db.db_instance_name}"
}

######################################################
#              IAM Role
######################################################
resource "aws_iam_role" "ecs_task_service_role_backend" {
  name                 = "Cloud9-${var.project}-ecs-task-service-role-backend"
  assume_role_policy   = data.aws_iam_policy_document.ecs_task_assume_role.json
  permissions_boundary = format("arn:aws:iam::%s:policy/netguru-boundary", data.aws_caller_identity.current.account_id)
}

resource "aws_iam_role_policy_attachment" "ecs_task_service_role_backend" {
  role       = aws_iam_role.ecs_task_service_role_backend.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
######################################################
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project}-backend"
  retention_in_days = 7
  tags              = local.default_tags
}

resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/ecs/${var.project}-postgres"
  retention_in_days = 7
  tags              = local.default_tags
}
######################################################

resource "aws_ecs_task_definition" "backend" {
  family = "${var.project}-backend"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  task_role_arn            = aws_iam_role.ecs_task_service_role_backend.arn
  execution_role_arn       = aws_iam_role.ecs_task_service_role_backend.arn

  container_definitions = jsonencode(
    [
      # backend app
      {
        name      = "backend"
        image     = "nginx:latest"
        cpu       = 512
        memory    = 1024
        essential = true

        portMappings = [
          {
            containerPort = 8000
            protocol      = "tcp"
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${var.project}-backend"
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "ecs"
          }
        }

        environment = [
          {
            "name" : "DEBUG",
            "value" : "True"
          },
          {
            "name" : "SECRET_KEY",
            "value" : "as78dhabys97dabiusdkasd"
          },
          {
            "name" : "DATABASE_URL",
            "value" : local.database_url
          },
        ]
      },
    ]
  )

  lifecycle {
    ignore_changes = [
      container_definitions
    ]
  }

  tags = local.default_tags
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project}-backend"
  cluster         = module.ecs_cluster.ecs_cluster_id
  task_definition = aws_ecs_task_definition.backend.arn

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
    target_group_arn = module.ecs_alb.target_group_arns[1]
    container_name   = "backend"
    container_port   = 8000
  }


  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }

  tags = local.default_tags
}
