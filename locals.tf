locals {
  tags = {
    role    = "website"
    domain  = var.website_domain
    managed = "terraform"
  }

  domain_redirect = var.website_redirect_www ? ["www.${var.website_domain}"] : []
  domains_all = concat(
    [var.website_domain],
    local.domain_redirect,
    var.website_aliases,
  )
  domains_alias = concat(
    local.domain_redirect,
    var.website_aliases,
  )

  domain_titled = replace(replace(title(var.website_domain), ".", ""), "-", "")

  cloudfront_certificate_arn = data.aws_acm_certificate.this.status == "ISSUED" ? aws_acm_certificate.this.arn : null
  cloudfront_default_certificate = data.aws_acm_certificate.this.status != "ISSUED" ? true : null
  cloudfront_alias = data.aws_acm_certificate.this.status == "ISSUED" ? local.domains_all : []
  cloudfront_web_acl_arn = var.cloudfront_web_acl_arn != "" ? var.cloudfront_web_acl_arn : null
}
