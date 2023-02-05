### Cloudfront

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "this" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "this" {
  name = var.cloudfront_response_headers_policy_name
}

resource "aws_cloudfront_distribution" "this" {
  aliases             = local.cloudfront_alias
  comment             = "Static Website for ${var.website_domain}"
  price_class         = var.cloudfront_price_class
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2and3"
  web_acl_id          = local.cloudfront_web_acl_arn

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    origin_id                = "S3-${var.website_domain}"
  }

  default_cache_behavior {
    allowed_methods  = var.cloudfront_default_cache_allowed_methods
    cached_methods   = var.cloudfront_default_cache_cached_methods
    target_origin_id = "S3-${var.website_domain}"

    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id            = data.aws_cloudfront_cache_policy.this.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.this.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.this.id
    compress                   = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.this.arn
    }
  }

  viewer_certificate {
    acm_certificate_arn            = local.cloudfront_certificate_arn
    cloudfront_default_certificate = local.cloudfront_default_certificate
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.cloudfront_ssl_minimum_protocol
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags

  depends_on = [aws_acm_certificate.this]

  #checkov:skip=CKV_AWS_68:WAF is enabled if ARN supplied via var.cloudfront_web_acl_arn
  #checkov:skip=CKV_AWS_86:FIXME Add logging support
  #checkov:skip=CKV2_AWS_32:Response header policy used is set via var.cloudfront_response_headers_policy_name
  #checkov:skip=CKV2_AWS_47:WAF is enabled if ARN supplied via var.cloudfront_web_acl_arn
}

### Cloudfront Access

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.website_domain
  description                       = "Static Website for ${var.website_domain}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

### Cloudfront Function

resource "aws_cloudfront_function" "this" {
  name    = replace(var.website_domain, ".", "-")
  runtime = "cloudfront-js-1.0"
  comment = "Viewer Request function for ${var.website_domain}"
  publish = true
  code    = templatefile(
    "${path.module}/functions/main.tftpl",
    {
      domain = var.website_domain,
      redirect_www = var.website_redirect_www,
    }
  )
}
