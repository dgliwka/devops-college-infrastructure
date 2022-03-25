resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.id
  name    = var.dns_zone
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.main.id
  name    = "api.${var.dns_zone}"
  type    = "A"

  alias {
    name                   = module.ecs_alb.lb_dns_name
    zone_id                = module.ecs_alb.lb_zone_id
    evaluate_target_health = false
  }
}
