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

output "s3_bucket" {
  description = "The name of the S3 Bucket"
  value       = aws_s3_bucket.website.bucket
}

output "cloudfront_url" {
  description = "The name of the Cloudfront URL."
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_url_redirect" {
  description = "The name of the Cloudfront URL providing redirects."
  value       = aws_cloudfront_distribution.website_redirect.domain_name
}
