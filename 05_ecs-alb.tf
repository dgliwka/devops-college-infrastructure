resource "aws_security_group" "internet_to_alb" {
  name        = "${var.project}-internet-to-alb"
  description = "Internet to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
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
      Name = "${var.project}-internet-to-alb"
    }
  )
}

module "ecs_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.7.0"

  name = "${var.project}-ecs-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  security_groups = [aws_security_group.internet_to_alb.id]
  subnets         = module.vpc.public_subnets

  target_groups = [
    {
      name                 = "${var.project}-ecs-frontend"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "ip"
      deregistration_delay = 30
      health_check = {
        healthy_threshold   = "3"
        interval            = "10"
        protocol            = "HTTP"
        matcher             = "200"
        timeout             = "5"
        path                = "/"
        unhealthy_threshold = "2"
      }
    },
    {
      name                 = "${var.project}-ecs-backend"
      backend_protocol     = "HTTP"
      backend_port         = 8000
      target_type          = "ip"
      deregistration_delay = 30
      health_check = {
        healthy_threshold   = "3"
        interval            = "10"
        protocol            = "HTTP"
        matcher             = "200"
        timeout             = "5"
        path                = "/api/tags"
        unhealthy_threshold = "2"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      action_type     = "fixed-response"
      certificate_arn = module.ecs_acm.acm_certificate_arn
      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  ]


  https_listener_rules = [
    {
      https_listener_index = 0
      actions = [{
        type               = "forward"
        target_group_index = 0
      }]
      conditions = [{
        host_headers = [var.dns_zone]
      }]
    },
    {
      https_listener_index = 0
      actions = [{
        type               = "forward"
        target_group_index = 1
      }]
      conditions = [{
        host_headers = ["api.${var.dns_zone}"]
      }]
    }
  ]

  tags = local.default_tags
}
