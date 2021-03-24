locals {
  origin_id = "S3-${var.domain}"

  tags = {
    role    = "website"
    domain  = var.domain
    managed = "terraform"
  }
}
