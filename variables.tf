variable "domain" {
  description = "The domain to use."
  type        = string
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
