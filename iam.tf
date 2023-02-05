data "aws_iam_policy_document" "pipeline" {
  statement {
    sid    = "AllowUploadToS3${local.domain_titled}"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    sid    = "AllowCloudFrontInvalidate${local.domain_titled}"
    effect = "Allow"
    actions = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.this.arn]
  }
}
