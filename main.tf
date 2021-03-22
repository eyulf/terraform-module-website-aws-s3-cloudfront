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
  name = var.user_group
}

resource "aws_iam_user" "uploader" {
  name = "s3_uploader_${var.domain}"
  path = "/websites/"

  tags = local.tags_production
}

resource "aws_iam_user_group_membership" "uploader" {
  user = aws_iam_user.uploader.name

  groups = [
    aws_iam_group.uploader.name,
  ]
}

resource "aws_iam_access_key" "uploader" {
  user = aws_iam_user.uploader.name
}

data "aws_iam_policy_document" "uploader" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.production.arn,
      "${aws_s3_bucket.production.arn}/*",
      aws_s3_bucket.staging.arn,
      "${aws_s3_bucket.staging.arn}/*",
    ]
  }
}

resource "aws_iam_user_policy" "uploader" {
  name   = "s3_uploader_${var.domain}"
  user   = aws_iam_user.uploader.name
  policy = data.aws_iam_policy_document.uploader.json
}

### S3 Bucket Policies

data "aws_iam_policy_document" "website_production" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.production.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.production.iam_arn]
    }
  }
}

data "aws_iam_policy_document" "website_production_redirect" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.production_redirect.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.production.iam_arn]
    }
  }
}

data "aws_iam_policy_document" "website_staging" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.staging.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.staging.iam_arn]
    }
  }
}

/*
 * S3 Bucket Configuration
 */

### Production S3 Bucket

resource "aws_s3_bucket" "production" {
  bucket = var.domain
  acl    = "private"

  website {
    index_document = "index.html"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    abort_incomplete_multipart_upload_days = 7
    enabled                                = true
    id                                     = "Purge old versions"
    tags                                   = {}

    noncurrent_version_expiration {
      days = 30
    }

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }
  }

  tags = local.tags_production
}

resource "aws_s3_bucket_policy" "production" {
  bucket = aws_s3_bucket.production.id
  policy = data.aws_iam_policy_document.website_production.json
}

### Production (Redirect) S3 Bucket

resource "aws_s3_bucket" "production_redirect" {
  bucket = "www.${var.domain}"
  acl    = "private"

  website {
    redirect_all_requests_to = "https://${var.domain}"
  }

  tags = local.tags_production
}

resource "aws_s3_bucket_policy" "production_redirect" {
  bucket = aws_s3_bucket.production_redirect.id
  policy = data.aws_iam_policy_document.website_production_redirect.json
}

### Staging S3 Bucket

resource "aws_s3_bucket" "staging" {
  bucket = "staging.${var.domain}"
  acl    = "private"

  website {
    index_document = "index.html"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    abort_incomplete_multipart_upload_days = 7
    enabled                                = true
    id                                     = "Purge old versions"
    tags                                   = {}

    noncurrent_version_expiration {
      days = 30
    }

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }
  }

  tags = local.tags_staging
}

resource "aws_s3_bucket_policy" "staging" {
  bucket = aws_s3_bucket.staging.id
  policy = data.aws_iam_policy_document.website_staging.json
}

/*
 * Cloudfront Configuration
 */

### Production Cloudfront

resource "aws_cloudfront_origin_access_identity" "production" {
  comment = var.domain
}

resource "aws_cloudfront_distribution" "production" {
  aliases             = [var.domain]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.production.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.production.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
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
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.production.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags_production
}

### Production (Redirect) Cloudfront

resource "aws_cloudfront_distribution" "production_redirect" {
  aliases         = ["www.${var.domain}"]
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.production_redirect.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.production.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.production.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags_production
}

### Staging Cloudfront

resource "aws_cloudfront_origin_access_identity" "staging" {
  comment = "staging.${var.domain}"
}

resource "aws_cloudfront_distribution" "staging" {
  aliases             = ["staging.${var.domain}"]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.staging.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.staging.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
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
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.staging.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags_staging
}

/*
 * ACM Configuration
 */

resource "aws_acm_certificate" "production" {
  provider = aws.virginia

  domain_name       = var.domain
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags_production
}

resource "cloudflare_record" "production_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.production.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.record
  type    = each.value.type
  ttl     = 120
}

resource "aws_acm_certificate_validation" "production" {
  provider = aws.virginia

  certificate_arn = aws_acm_certificate.production.arn
}

### Staging ACM

resource "aws_acm_certificate" "staging" {
  provider = aws.virginia

  domain_name       = "staging.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags_staging
}

resource "cloudflare_record" "staging_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.staging.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.record
  type    = each.value.type
  ttl     = 120
}

resource "aws_acm_certificate_validation" "staging" {
  provider = aws.virginia

  certificate_arn = aws_acm_certificate.staging.arn
}

/*
 * Cloudflare Configuration
 */

resource "cloudflare_record" "website_root" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  value   = aws_cloudfront_distribution.production.domain_name
  type    = "CNAME"
  ttl     = 3600
}

resource "cloudflare_record" "website_redirect" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = aws_cloudfront_distribution.production_redirect.domain_name
  type    = "CNAME"
  ttl     = 3600
}

resource "cloudflare_record" "website_staging" {
  zone_id = var.cloudflare_zone_id
  name    = "staging"
  value   = aws_cloudfront_distribution.staging.domain_name
  type    = "CNAME"
  ttl     = 3600
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

  name             = "${replace(var.domain, ".", "")}-cloudfront-redirect"
  application_id   = data.aws_serverlessapplicationrepository_application.standard_redirects_for_cloudfront.application_id
  semantic_version = data.aws_serverlessapplicationrepository_application.standard_redirects_for_cloudfront.semantic_version
  capabilities     = ["CAPABILITY_IAM"] # Manually set due to capability removing itself after first deploy
}
