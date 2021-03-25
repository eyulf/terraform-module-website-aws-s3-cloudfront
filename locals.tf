locals {
  origin_id = "S3-${var.website_domain}"

  tags = {
    role    = "website"
    domain  = var.website_domain
    managed = "terraform"
  }
}
