output "acm_validation_dns_records" {
  description = "The DNS records required to validate the ACM Certificate."
  value       = var.route53_zone_id == "" ? aws_acm_certificate.this.domain_validation_options : null
}

output "s3_bucket" {
  description = "The name of the S3 Bucket."
  value       = aws_s3_bucket.this.bucket
}

output "cloudfront_arn" {
  description = "The ARN of the Cloudfront Distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "cloudfront_url" {
  description = "The name of the Cloudfront Distribution's URL."
  value       = var.route53_zone_id == "" ? aws_cloudfront_distribution.this.domain_name : null
}

output "github_openid_connect_arn" {
  description = "The ARN of the GitHub OpenID Connect Provider."
  value       = var.openid_provider_create && var.github_repo != "" ? aws_iam_openid_connect_provider.github[0].arn : null
}

output "github_openid_connect_role" {
  description = "The name of the GitHub OpenID Connect IAM Role."
  value       = var.github_repo != "" ? aws_iam_role.github[0].id : null
}

output "bitbucket_openid_connect_arn" {
  description = "The ARN of the BitBucket OpenID Connect Provider."
  value       = var.openid_provider_create && var.bitbucket_repo_uuid != "" ? aws_iam_openid_connect_provider.bitbucket[0].arn : null
}

output "bitbucket_openid_connect_role" {
  description = "The name of the BitBucket OpenID Connect IAM Role."
  value       = var.bitbucket_repo_uuid != "" ? aws_iam_role.bitbucket[0].id : null
}

output "iam_policy_data_json" {
  description = "IAM policy data that can be used for S3 uploads and CloudFront invalidation."
  value       = data.aws_iam_policy_document.pipeline.json
}
