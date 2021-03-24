output "iam_user_access_key_id" {
  description = "The Access Key ID of the IAM user used for uploading to the S3 bucket"
  value       = aws_iam_access_key.uploader.id
  sensitive   = true
}

output "iam_user_secret_access_key" {
  description = "The Secret Access Key of the IAM user used for uploading to the S3 bucket"
  value       = aws_iam_access_key.uploader.secret
  sensitive   = true
}

output "s3_bucket_prod" {
  description = "The name of the production S3 Bucket"
  value       = aws_s3_bucket.production.bucket
}

output "s3_bucket_staging" {
  description = "The name of the staging S3 Bucket"
  value       = var.enable_staging == true ? aws_s3_bucket.staging[0].bucket : null
}

output "cloudfront_url_prod" {
  description = "The name of the production Cloudfront URL."
  value       = aws_cloudfront_distribution.production.domain_name
}

output "cloudfront_url_prod_redirect" {
  description = "The name of the production redirect Cloudfront URL."
  value       = aws_cloudfront_distribution.production_redirect.domain_name
}

output "cloudfront_url_staging" {
  description = "The name of the staging Cloudfront URL."
  value       = var.enable_staging == true ? aws_cloudfront_distribution.staging[0].domain_name : null
}
