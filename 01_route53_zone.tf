resource "aws_route53_zone" "main" {
  name    = var.dns_zone
  comment = "${var.project}-${var.environment}"

  delegation_set_id = var.dns_delegation_set

  tags = local.default_tags
}
