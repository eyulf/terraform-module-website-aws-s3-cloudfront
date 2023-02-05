### ACM Configuration

resource "aws_acm_certificate" "this" {
  provider = aws.virginia

  domain_name       = var.website_domain
  validation_method = "DNS"

  subject_alternative_names = local.domains_alias

  tags = local.tags

  # This is required as the Certificate cannot be destroyed if in use by CloudFront
  lifecycle {
    create_before_destroy = true
  }
}

# This data resource is used to ensure that the ACM is issued before attempting to add it to CloudFront

data "aws_acm_certificate" "this" {
  provider = aws.virginia

  domain      = var.website_domain
  statuses    = [
    "PENDING_VALIDATION",
    "ISSUED",
  ]
  types       = ["AMAZON_ISSUED"]

  depends_on = [aws_acm_certificate.this]
}

resource "aws_route53_record" "website_acm_validation" {
  for_each = {
    for dvo in var.route53_zone_id != "" ? aws_acm_certificate.this.domain_validation_options : [] : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  provider = aws.virginia
  count    = var.route53_zone_id != "" ? 1 : 0

  certificate_arn = aws_acm_certificate.this.arn
}

### DNS Configuration

### Route53

resource "aws_route53_record" "website" {
  count = var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.website_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "website_www" {
  count = var.website_redirect_www && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "www.${var.website_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = true
  }
}
