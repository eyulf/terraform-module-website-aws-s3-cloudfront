variable "domain" {
  description = "The domain to use."
  type        = string
}

variable "create_iam_group" {
  description = "Toggle creating a IAM user for S3 uploads."
  default     = true
  type        = bool
}

variable "create_iam_user" {
  description = "Toggle creating a IAM user for S3 uploads."
  default     = true
  type        = bool
}

variable "user_group" {
  description = "The IAM group to add the S3 Uploader user."
  default     = "s3_Uploaders"
  type        = string
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
