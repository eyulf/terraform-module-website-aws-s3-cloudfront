variable "cloudflare_zone_id" {
  description = "The Cloudflare Zone ID. Not Required if `route53_zoneid` is provided."
  default     = ""
  type        = string
}

variable "cloudfront_default_cache_allowed_methods" {
  description = "List of allowed methods for the Cloudfront default cache behaviour configuration."
  default     = ["GET", "HEAD"]
  type        = list(string)
}

variable "cloudfront_default_cache_cached_methods" {
  description = "List of cached_methods for the Cloudfront default cache behaviour configuration."
  default     = ["GET", "HEAD"]
  type        = list(string)
}

variable "cloudfront_default_cache_default_ttl" {
  description = "The default ttl value for the Cloudfront default cache behaviour configuration."
  default     = 3600
  type        = number
}

variable "cloudfront_default_cache_max_ttl" {
  description = "The maximum ttl value for the Cloudfront default cache behaviour configuration."
  default     = 86400
  type        = number
}

variable "cloudfront_default_cache_min_ttl" {
  description = "The minimum ttl value for the Cloudfront default cache behaviour configuration."
  default     = 0
  type        = number
}

variable "cloudfront_ssl_minimum_protocol" {
  description = "The minimum SSL protocol to use for the Cloudfront viewer certificate configuration."
  default     = "TLSv1.2_2019"
  type        = string
}

variable "iam_group_create" {
  description = "When set to `true` this will create and manage the IAM group. When set to `false` it will use a data resource instead."
  default     = true
  type        = bool
}

variable "iam_group_name" {
  description = "The name of the IAM group that the IAM user will be added to."
  default     = "s3_uploaders"
  type        = string
}

variable "iam_user_create" {
  description = "When set to `true` this will create and manage the IAM user."
  default     = true
  type        = bool
}

variable "iam_user_keys_create" {
  description = "When set to `true` this will create and output the Access Key ID and Secret Access Keys for the IAM user."
  default     = false
  type        = bool
}

variable "iam_user_path" {
  description = "The path used for the IAM user."
  default     = "/websites/"
  type        = string
}

variable "iam_user_prefix_name" {
  description = "The prefix used at the beginning of the IAM user's name."
  default     = "s3_uploader"
  type        = string
}

variable "route53_zone_id" {
  description = "The Route53 Zone ID. Not Required if `cloudflare_zone_id` is provided."
  default     = ""
  type        = string
}

variable "s3_cors_allowed_headers" {
  description = "List of allowed headers for the S3 Bucket's CORS configuration."
  default     = []
  type        = list(string)
}

variable "s3_cors_allowed_methods" {
  description = "List of allowed methods for the S3 Bucket's CORS configuration."
  default     = ["GET"]
  type        = list(string)
}
variable "s3_cors_allowed_origins" {
  description = "List of allowed origins for the S3 Bucket's CORS configuration."
  default     = []
  type        = list(string)
}

variable "s3_cors_expose_headers" {
  description = "List of expose headers for the S3 Bucket's CORS configuration."
  default     = []
  type        = list(string)
}

variable "s3_lifecycle_noncurrent_expiration" {
  description = "The number of days after which a non current version of a S3 object will be expired."
  default     = 30
  type        = number
}

variable "website_domain" {
  description = "The primary domain name to use for the website."
  type        = string
}

variable "website_redirect_www" {
  description = "When set to `true` this will create a s3 bucket and cloudfront distribution to redirect www.`website_domain` to `website_domain`."
  default     = true
  type        = bool
}
