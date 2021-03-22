terraform {
  required_version = ">= 0.12"
}

locals {
  origin_id = "S3-${var.domain}"

  tags = {
    role   = "website"
    domain = var.domain
  }
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "aws_iam_policy_document" "user" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.default.arn}",
      "${aws_s3_bucket.default.arn}/*",
      "${aws_s3_bucket.staging.arn}",
      "${aws_s3_bucket.staging.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "website" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.default.arn}/*"]

    principals {
      type = "*"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.default.arn]

    principals {
      type = "*"
      identifiers = ["*"]
    }
  }
}

//**************************************************************************************************
data "aws_iam_policy_document" "website_redirect" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.default_redirect.arn}/*"]

    principals {
      type = "*"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.default_redirect.arn]

    principals {
      type = "*"
      identifiers = ["*"]
    }
  }
}

//**************************************************************************************************
data "aws_iam_policy_document" "website_staging" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.staging.arn}/*"]

    principals {
      type = "*"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.staging.arn]

    principals {
      type = "*"
      identifiers = ["*"]
    }
  }
}

/***************************************************************************************************
 * IAM User
 */

resource "aws_iam_group" "default" {
  name = var.user_group
}

resource "aws_iam_user" "default" {
  name = "s3_uploader_${var.domain}"
  path = "/websites/"
  tags = local.tags
}

resource "aws_iam_user_group_membership" "default" {
  user = aws_iam_user.default.name

  groups = [
    aws_iam_group.default.name,
  ]
}

resource "aws_iam_access_key" "default" {
  user = aws_iam_user.default.name
}

resource "aws_iam_user_policy" "default" {
  name   = "s3_uploader_${var.domain}"
  user   = aws_iam_user.default.name
  policy = data.aws_iam_policy_document.user.json
}

/***************************************************************************************************
 * S3 Bucket
 */

resource "aws_s3_bucket" "default" {
  bucket = var.domain
  acl    = "public-read"
  tags   = local.tags

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
}

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.default.id
  policy = data.aws_iam_policy_document.website.json
}

//**************************************************************************************************
resource "aws_s3_bucket" "default_redirect" {
  bucket = "www.${var.domain}"
  acl    = "public-read"
  tags   = local.tags

  website {
    redirect_all_requests_to = "https://${var.domain}"
  }
}

resource "aws_s3_bucket_policy" "default_redirect" {
  bucket = aws_s3_bucket.default_redirect.id
  policy = data.aws_iam_policy_document.website_redirect.json
}

//**************************************************************************************************
resource "aws_s3_bucket" "staging" {
  bucket = "staging.${var.domain}"
  acl    = "public-read"
  tags   = local.tags

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
}

resource "aws_s3_bucket_policy" "staging" {
  bucket = aws_s3_bucket.staging.id
  policy = data.aws_iam_policy_document.website_staging.json
}

/***************************************************************************************************
 * SSL Certificate
 */

resource "aws_acm_certificate" "default" {
  provider = aws.virginia
  domain_name = var.domain
  subject_alternative_names = [
    "www.${var.domain}",
    "staging.${var.domain}",
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "cloudfront_validation_root" {
  domain  = var.domain
  name    = replace(aws_acm_certificate.default.domain_validation_options.0.resource_record_name, ".${var.domain}.", "")
  value   = replace(aws_acm_certificate.default.domain_validation_options.0.resource_record_value, "/\\.$/", "")
  type    = aws_acm_certificate.default.domain_validation_options.0.resource_record_type
  ttl     = 120
}

resource "cloudflare_record" "cloudfront_validation_redirect" {
  domain  = var.domain
  name    = replace(aws_acm_certificate.default.domain_validation_options.1.resource_record_name, ".${var.domain}.", "")
  value   = replace(aws_acm_certificate.default.domain_validation_options.1.resource_record_value, "/\\.$/", "")
  type    = aws_acm_certificate.default.domain_validation_options.1.resource_record_type
  ttl     = 120
}

resource "cloudflare_record" "cloudfront_validation_staging" {
  domain  = var.domain
  name    = replace(aws_acm_certificate.default.domain_validation_options.2.resource_record_name, ".${var.domain}.", "")
  value   = replace(aws_acm_certificate.default.domain_validation_options.2.resource_record_value, "/\\.$/", "")
  type    = aws_acm_certificate.default.domain_validation_options.2.resource_record_type
  ttl     = 120
}

resource "aws_acm_certificate_validation" "default" {
  provider = aws.virginia
  certificate_arn = aws_acm_certificate.default.arn
  validation_record_fqdns = [
    cloudflare_record.cloudfront_validation_root.hostname,
    cloudflare_record.cloudfront_validation_redirect.hostname,
    cloudflare_record.cloudfront_validation_staging.hostname,
  ]
}

/***************************************************************************************************
 * Cloudfront
 */

resource "aws_cloudfront_distribution" "default" {
  origin {
    domain_name = aws_s3_bucket.default.website_endpoint
    origin_id = local.origin_id

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  aliases = [var.domain]

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

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
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.default.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

//**************************************************************************************************
resource "aws_cloudfront_distribution" "default_redirect" {
  origin {
    domain_name = aws_s3_bucket.default_redirect.website_endpoint
    origin_id = local.origin_id

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  aliases = ["www.${var.domain}"]

  enabled = true
  is_ipv6_enabled = true

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
    acm_certificate_arn = aws_acm_certificate_validation.default.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

//**************************************************************************************************
resource "aws_cloudfront_distribution" "staging" {
  origin {
    domain_name = aws_s3_bucket.staging.website_endpoint
    origin_id = local.origin_id

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  aliases = ["staging.${var.domain}"]

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

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
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.default.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

/***************************************************************************************************
 * Cloudflare
 */

resource "cloudflare_record" "website_root" {
  domain  = var.domain
  name    = var.domain
  value   = aws_cloudfront_distribution.default.domain_name
  type    = "CNAME"
  ttl     = 3600
}

resource "cloudflare_record" "website_redirect" {
  domain  = var.domain
  name    = "www"
  value   = aws_cloudfront_distribution.default_redirect.domain_name
  type    = "CNAME"
  ttl     = 3600
}

resource "cloudflare_record" "website_staging" {
  domain  = var.domain
  name    = "staging"
  value   = aws_cloudfront_distribution.staging.domain_name
  type    = "CNAME"
  ttl     = 3600
}
