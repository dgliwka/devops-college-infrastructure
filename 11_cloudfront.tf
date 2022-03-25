module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  providers = {
    aws = aws.us-east-1
  }

  aliases = [var.dns_zone]

  comment             = "${var.dns_zone} CloudFront"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  origin = {
    ecs_frontend = {
      domain_name = module.ecs_alb.lb_dns_name
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "ecs_frontend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true

    use_forwarded_values = false
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id   = "216adef6-5c7f-47e4-b989-5492eafa07d3"
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
  }

  viewer_certificate = {
    acm_certificate_arn = module.cdn_acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }
}
