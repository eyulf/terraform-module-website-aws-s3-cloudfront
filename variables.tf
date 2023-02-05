variable "website_domain" {
  description = "The primary domain name to use for the website."
  type        = string
}

variable "website_aliases" {
  description = "Additional domain names to use for the website."
  type        = list(string)
  default     = []
}

variable "website_redirect_www" {
  description = "Include www in the Cloudfront Alias and ACM Certificate as well as add code to redirect www to non-www in the Cloudfront Function."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "The Route53 Zone ID. If not set DNS records will be returned in outputs."
  type        = string
  default     = ""
}

### S3

variable "s3_cors_allowed_headers" {
  description = "List of allowed headers for the S3 Bucket's CORS configuration."
  type        = list(string)
  default     = []
}

variable "s3_cors_allowed_methods" {
  description = "List of allowed methods for the S3 Bucket's CORS configuration."
  type        = list(string)
  default     = ["GET"]
}
variable "s3_cors_allowed_origins" {
  description = "List of allowed origins for the S3 Bucket's CORS configuration."
  type        = list(string)
  default     = ["*"]
}

variable "s3_cors_expose_headers" {
  description = "List of expose headers for the S3 Bucket's CORS configuration."
  type        = list(string)
  default     = []
}

variable "s3_lifecycle_noncurrent_expiration" {
  description = "The number of days after which a non current version of a S3 object will be expired."
  type        = number
  default     = 30
}

### CloudFront

variable "cloudfront_default_cache_allowed_methods" {
  description = "List of allowed methods for the CloudFront default cache behaviour configuration."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cloudfront_default_cache_cached_methods" {
  description = "List of cached_methods for the CloudFront default cache behaviour configuration."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cloudfront_price_class" {
  description = "The price class to use for CloudFront. Must be one of `PriceClass_All`, `PriceClass_200` or `PriceClass_100`."
  type        = string
  default     = "PriceClass_All"
}

variable "cloudfront_ssl_minimum_protocol" {
  description = "The minimum SSL protocol to use for the CloudFront viewer certificate configuration."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "cloudfront_web_acl_arn" {
  description = "The ARN of an AWS WAF web ACL to associate with CloudFront."
  type        = string
  default     = ""
}

variable "cloudfront_response_headers_policy_name" {
  description = "The Name of the Response headers policy to use."
  type        = string
  default     = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}

### OpenID

variable "openid_provider_create" {
  description = "Create the OpenID Connect Provider."
  type        = bool
  default     = false
}

variable "github_openid_arn" {
  description = "The ARN for an existing GitHub OpenID Connect provider."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "The name of the GitHub repo in the format of 'organisation/repo'."
  type        = string
  default     = ""
}

variable "bitbucket_openid_arn" {
  description = "The ARN for an existing BitBucket OpenID Connect provider."
  type        = string
  default     = ""
}

variable "bitbucket_workspace_uuid" {
  description = "BitBucket Workspace UUID."
  type        = string
  default     = ""
}

variable "bitbucket_workspace_name" {
  description = "The name of the BitBucket workspace."
  type        = string
  default     = ""
}

variable "bitbucket_repo_uuid" {
  description = "A list of Repo UUID's"
  type        = string
  default     = ""
}
