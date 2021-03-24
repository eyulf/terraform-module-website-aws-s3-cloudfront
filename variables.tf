variable "domain" {
  description = "The domain to use."
  type        = string
}

variable "user_group" {
  description = "The IAM group to add the S3 Uploader user."
  default     = "s3_Uploaders"
  type        = string
}

variable "create_iam_group" {
  description = "Toggle creating a IAM group for S3 uploads."
  default     = true
  type        = bool
}

variable "create_iam_user" {
  description = "Toggle creating a IAM user for S3 uploads."
  default     = true
  type        = bool
}

variable "create_iam_keys" {
  description = "Toggle creating the Access Keys for the IAM user."
  default     = false
  type        = bool
}

variable "create_www_redirect" {
  description = "Toggle creating a redirect from www.domain to domain."
  default     = true
  type        = bool
}

variable "cloudflare_zone_id" {
  description = "The Cloudflare Zone ID."
  type        = string
}

variable "s3_cors_allowed_origins" {
  description = "Specifies which origins are allowed for the S3 CORS configuration."
  default     = []
  type        = list(string)
}
