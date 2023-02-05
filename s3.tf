### S3 Bucket Configuration

resource "aws_s3_bucket" "this" {
  bucket = var.website_domain
  tags   = local.tags

  #checkov:skip=CKV_AWS_18:Access logging not currently used
  #checkov:skip=CKV_AWS_144:Cross-region replication not required
  #checkov:skip=CKV_AWS_145:Default encryption is used instead
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "terraform"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.s3_lifecycle_noncurrent_expiration
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = var.s3_cors_allowed_headers
    allowed_methods = var.s3_cors_allowed_methods
    allowed_origins = var.s3_cors_allowed_origins
    expose_headers  = var.s3_cors_expose_headers
    max_age_seconds = 0
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = data.aws_iam_policy_document.s3_bucket.json
}

data "aws_iam_policy_document" "s3_bucket" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}
