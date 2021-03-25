/*
 * Provider Configuration
 */

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

/*
 * IAM Configuration
 */

### IAM Uploader user and group

resource "aws_iam_group" "uploader" {
  count = var.iam_group_create ? 1 : 0

  name = var.iam_group_name
}

data "aws_iam_group" "uploader" {
  count = var.iam_group_create ? 0 : 1

  group_name = var.iam_group_name
}

resource "aws_iam_user" "uploader" {
  count = var.iam_user_create ? 1 : 0

  name = "${var.iam_user_prefix_name}_${var.website_domain}"
  path = var.iam_user_path

  tags = local.tags
}

resource "aws_iam_user_group_membership" "uploader_created" {
  count = var.iam_user_create && var.iam_group_create ? 1 : 0

  user = aws_iam_user.uploader[0].name

  groups = [
    aws_iam_group.uploader[0].name,
  ]
}

resource "aws_iam_user_group_membership" "uploader_existing" {
  count = var.iam_user_create && !var.iam_group_create ? 1 : 0

  user = aws_iam_user.uploader[0].name

  groups = [
    data.aws_iam_group.uploader[0].group_name,
  ]
}

resource "aws_iam_access_key" "uploader" {
  count = var.iam_user_create && var.iam_user_keys_create ? 1 : 0

  user = aws_iam_user.uploader[0].name
}

data "aws_iam_policy_document" "uploader" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.website.arn,
      "${aws_s3_bucket.website.arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "uploader" {
  count = var.iam_user_create ? 1 : 0

  name   = "${var.iam_user_prefix_name}_${var.website_domain}"
  user   = aws_iam_user.uploader[0].name
  policy = data.aws_iam_policy_document.uploader.json
}

### S3 Bucket Policies

data "aws_iam_policy_document" "website" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}

data "aws_iam_policy_document" "website_redirect" {
  count = var.website_redirect_www ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_redirect[0].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}

/*
 * S3 Bucket Configuration
 */

resource "aws_s3_bucket" "website" {
  bucket = var.website_domain
  acl    = "private"

  website {
    index_document = "index.html"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  cors_rule {
    allowed_headers = var.s3_cors_allowed_headers
    allowed_methods = var.s3_cors_allowed_methods
    allowed_origins = var.s3_cors_allowed_origins
    expose_headers  = var.s3_cors_expose_headers
    max_age_seconds = 0
  }

  lifecycle_rule {
    abort_incomplete_multipart_upload_days = 7
    enabled                                = true
    id                                     = "Purge old versions"
    tags                                   = {}

    noncurrent_version_expiration {
      days = var.s3_lifecycle_noncurrent_expiration
    }

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website.json
}

### S3 Bucket (Redirect)

resource "aws_s3_bucket" "website_redirect" {
  count = var.website_redirect_www ? 1 : 0

  bucket = "www.${var.website_domain}"
  acl    = "private"

  website {
    redirect_all_requests_to = "https://${var.website_domain}"
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    abort_incomplete_multipart_upload_days = 7
    enabled                                = true
    id                                     = "Purge old versions"
    tags                                   = {}

    noncurrent_version_expiration {
      days = var.s3_lifecycle_noncurrent_expiration
    }

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "website_redirect" {
  count = var.website_redirect_www ? 1 : 0

  bucket = aws_s3_bucket.website_redirect[0].id
  policy = data.aws_iam_policy_document.website_redirect[0].json
}

/*
 * Cloudfront Configuration
 */

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.website_domain
}

resource "aws_cloudfront_distribution" "website" {
  aliases             = [var.website_domain]
  price_class         = var.cloudfront_price_class
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = var.cloudfront_default_cache_allowed_methods
    cached_methods   = var.cloudfront_default_cache_cached_methods
    target_origin_id = local.origin_id

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_serverlessapplicationrepository_cloudformation_stack.standard_redirects_for_cloudfront.outputs["StandardRedirectsForCloudFrontVersionOutput"]
      include_body = false
    }

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.cloudfront_default_cache_min_ttl
    default_ttl            = var.cloudfront_default_cache_default_ttl
    max_ttl                = var.cloudfront_default_cache_max_ttl
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.website.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.cloudfront_ssl_minimum_protocol
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags
}

### Cloudfront (Redirect)

resource "aws_cloudfront_distribution" "website_redirect" {
  count = var.website_redirect_www ? 1 : 0

  aliases         = ["www.${var.website_domain}"]
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.website_redirect[0].bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = var.cloudfront_default_cache_allowed_methods
    cached_methods   = var.cloudfront_default_cache_cached_methods
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.cloudfront_default_cache_min_ttl
    default_ttl            = var.cloudfront_default_cache_default_ttl
    max_ttl                = var.cloudfront_default_cache_max_ttl
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.website.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.cloudfront_ssl_minimum_protocol
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags
}

/*
 * ACM Configuration
 */

resource "aws_acm_certificate" "website" {
  provider = aws.virginia

  domain_name       = var.website_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.website_domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "cloudflare_record" "website_acm_validation" {
  for_each = {
    for dvo in var.cloudflare_zone_id != "" ? aws_acm_certificate.website.domain_validation_options : [] : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = trimsuffix(dvo.resource_record_value, ".")
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.record
  type    = each.value.type
  ttl     = 120
}

resource "aws_route53_record" "website_acm_validation" {
  for_each = {
    for dvo in var.route53_zone_id != "" ? aws_acm_certificate.website.domain_validation_options : [] : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "website" {
  provider = aws.virginia

  certificate_arn = aws_acm_certificate.website.arn
}

/*
 * DNS Configuration
 */

### Cloudflare

resource "cloudflare_record" "website" {
  count = var.cloudflare_zone_id != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.website_domain
  value   = aws_cloudfront_distribution.website.domain_name
  type    = "CNAME"
  ttl     = 3600
}

resource "cloudflare_record" "website_redirect" {
  count = var.website_redirect_www && var.cloudflare_zone_id != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = aws_cloudfront_distribution.website_redirect[0].domain_name
  type    = "CNAME"
  ttl     = 3600
}

### Route53

resource "aws_route53_record" "website" {
  count = var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.website_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "production_redirect" {
  count = var.website_redirect_www && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "www.${var.website_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_redirect[0].domain_name
    zone_id                = aws_cloudfront_distribution.website_redirect[0].hosted_zone_id
    evaluate_target_health = true
  }
}

/*
 * Lambda Configuration
 */

data "aws_serverlessapplicationrepository_application" "standard_redirects_for_cloudfront" {
  provider       = aws.virginia
  application_id = "arn:aws:serverlessrepo:us-east-1:621073008195:applications/standard-redirects-for-cloudfront"
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "standard_redirects_for_cloudfront" {
  provider = aws.virginia

  name             = "${replace(var.website_domain, ".", "")}-cloudfront-redirect"
  application_id   = data.aws_serverlessapplicationrepository_application.standard_redirects_for_cloudfront.application_id
  semantic_version = data.aws_serverlessapplicationrepository_application.standard_redirects_for_cloudfront.semantic_version
  capabilities     = ["CAPABILITY_IAM"] # Manually set due to capability removing itself after first deploy
}
