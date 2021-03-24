variable "domain" {
  description = "The domain to use."
  type        = string
}

variable "user_group" {
  description = "The IAM group to add the S3 Uploader user."
  default     = "s3_Uploaders"
  type        = string
}

variable "enable_staging" {
   description = "Determines if a staging environment is created."
   default     = true
}

variable "cloudflare_zone_id" {
  description = "The Cloudflare Zone ID."
  type        = string
}

variable "s3_cors_allowed_origins" {
  description = "Specifies which origins are allowed for the S3 CORS configuration."
  type        = list(string)
}
