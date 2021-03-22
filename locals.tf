locals {
  origin_id = "S3-${var.domain}"

  tags_production = {
    role    = "website"
    env     = "production"
    domain  = var.domain
    managed = "terraform"
  }

  tags_staging = {
    role    = "website"
    env     = "staging"
    domain  = var.domain
    managed = "terraform"
  }
}
