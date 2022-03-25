module "ecs_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.3.0"

  domain_name = var.dns_zone
  zone_id     = aws_route53_zone.main.id

  subject_alternative_names = [
    "*.${var.dns_zone}",
  ]
}

module "cdn_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.3.0"

  providers = {
    aws = aws.us-east-1
  }

  domain_name = var.dns_zone
  zone_id     = aws_route53_zone.main.id

  subject_alternative_names = [
    "*.${var.dns_zone}",
  ]
}
