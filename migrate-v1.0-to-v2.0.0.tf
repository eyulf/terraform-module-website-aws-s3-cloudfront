# https://www.terraform.io/language/modules/develop/refactoring

moved {
  from = aws_acm_certificate.website
  to   = aws_acm_certificate.this
}

moved {
  from = aws_s3_bucket.website
  to   = aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.website
  to   = aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_versioning.website
  to   = aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.website
  to   = aws_s3_bucket_lifecycle_configuration.this
}

moved {
  from = aws_s3_bucket_cors_configuration.website
  to   = aws_s3_bucket_cors_configuration.this
}

moved {
  from = aws_s3_bucket_policy.website
  to   = aws_s3_bucket_policy.this
}

moved {
  from = aws_cloudfront_distribution.website
  to   = aws_cloudfront_distribution.this
}
