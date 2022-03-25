resource "aws_security_group" "to_rds" {
  name        = "${var.project}-to-rds"
  description = "To RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.alb_to_ecs.id,
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
      Name = "${var.project}-to-rds"
    }
  )
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "3.5.0"

  identifier = "${var.project}-db"

  engine               = "postgres"
  engine_version       = "14.1"
  major_engine_version = "14"
  family               = "postgres14"

  instance_class    = "db.t4g.micro"
  allocated_storage = 5

  name     = "${var.project}_db"
  username = "mietek"
  password = "jei3aChoh1ahwiP"
  port     = "5432"

  vpc_security_group_ids = [aws_security_group.to_rds.id]
  subnet_ids             = module.vpc.private_subnets

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  backup_retention_period         = 0

  tags = local.default_tags
}
