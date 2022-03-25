module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 3.4.0"

  name = "${var.project}-${var.environment}"

  container_insights = true

  capacity_providers = [
    "FARGATE"
  ]

  tags = local.default_tags
}

resource "aws_security_group" "alb_to_ecs" {
  name        = "${var.project}-alb-to-ecs"
  description = "ALB to ECS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    security_groups = [
      aws_security_group.internet_to_alb.id,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.project}-alb-to-ecs"
    }
  )
}
