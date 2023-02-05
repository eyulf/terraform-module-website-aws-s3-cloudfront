# Terraform AWS S3/CloudFront Website

## Contents
- [Introduction](#introduction)
  - [WWW Redirect](#www-redirect)
  - [OpenID Connect](#openid-connect)
  - [Module Limitations](#module-limitations)
  - [Upgrade Notes](#upgrade-notes)
- [Usage](#usage)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction

This module will create and configure a CloudFront Distribution and S3 bucket to allow a static website to be hosted. This is secured using a CloudFront Origin Access Control, as such this module will not configure the S3 bucket to be directly accessible, instead requests _must_ go through the CloudFront Distribution.

There are some limitations with this configuration as it requires that Website hosting is not enabled on the S3 bucket. Additionally CloudFront only applies the default root object on the root of the website itself (eg `example.com` > `example.com/index.html`). This is not performed on any subdirectories (eg `example.com/about/`). To work around this limitation, A CloudFront Function is also deployed to append `index.html` to requests that don’t include a file name or extension in the URL.

For DNS hosting, you can supply a Route53 zone ID using `var.route53_zone_id`. DNS records will be created in when this is supplied. The zone itself is not created or managed by this module. When this is not supplied the relevent DNS records will be supplied in outputs.

The CloudFront distribution is configured with Cache Policies. The Cache policy is set to `CachingOptimized`, the Origin request policy is set to `CORS-S3Origin`. Additionally the Reponse headers policy is also set, the policy used is configurable and is set to `Managed-CORS-with-preflight-and-SecurityHeadersPolicy` by default.

### WWW Redirect

If you want to redirect your website's www domain to the non-www domain (eg `www.example.com` to `example.com`), you can do this using by enabling the `website_redirect_www` variable. Enabling this will do a couple of things at once:

1. Includes the www version of the website in the list of alias domains. This impacts the configuration of the ACM certificate and CloudFront Distribution.
1. Include code in the CloudFront Function to perform a 302 redirect from www to non-www (eg this will redirect `www.example.com` to `example.com`).

Note: If you want to include the www domain but _ DO NOT_ want to redirect it, you will need to include it in the `website_aliases` variable instead.

### OpenID Connect

This module prefers OpenID Connect for authenticating against AWS for deploying files to S3 and invalidating CloudFront cache. The intended use case for this is as part of a [Github Action](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services), or a [Bitbucket Pipeline](https://support.atlassian.com/bitbucket-cloud/docs/deploy-on-aws-using-bitbucket-pipelines-openid-connect).

If you do not use any of the above to manage/deploy your code to S3, you can make use of the IAM Policy Document provided as the `iam_policy_data_json` output to configure your own IAM access.

### Module Limitations

**Intial Deployment**

When first using this module, you will need to run a Terraform Apply twice. This is because of the ACM data resource that is used to ensure that the ACM certificate is issued before adding it to CloudFront regardless of how the DNS validation records are created.

The first Terraform Apply will create everything, the second Terraform Apply will add the domain/s and ACM certificate to the CloudFront Distribution.

**ACM Certificate Replacement**

If the ACM certicate needs to be replaced by Terraform, the Apply will fail with the following error:

`multiple certificates for domain "example.com" found in this Region`

This is caused by the ACM data resource finding multiple records. To resolve this take the following steps in the AWS Console (or via API).

1. Update the CloudFront Distribution to remove the Aliases and ACM Certificate.
1. Delete the old SSL Certificate that does not contain the new domain configuration.

After this is done you can then run another Terraform Apply to finalise the changes.

Note: The ACM Certificate will need to be replaced in the following situations:

- Changing the `website_redirect_www` variable.
- Updating the `website_aliases` variable.

If you need to do any of the above activities, you should treat this as a breaking change for the purposes of change/downtime management.

### Upgrade Notes

In version 1.0 of this module, there was capability to create an IAM user to be used for uploading files. From version 2.0.0 onwards, this has been removed in favour of OpenID Connect. If this is not desired, this module will still output an IAM Policy Document that can be used for providing access.

Version 2.0.0 of this module also replaces the S3 bucket and CloudFront Distribution previously only used for redirecting www to non-www with a CloudFront Function that is associated with the primary CloudFront Distribution. This may cause an outage if the www version of a website is pointing to the CLoudFront Distribution that gets removed.

## Usage

**Default (External DNS)**
```hcl
module "website-aws-s3-cloudfront-cloudflare" {
  source  = "eyulf/website-aws-s3-cloudfront/module"
  version = "2.0.0"

  website_domain = "example.com"

  providers = {
    aws.virginia = aws.n_virginia
  }
}
```

**Default (Route53)**
```hcl
module "website-aws-s3-cloudfront-route53" {
  source  = "eyulf/website-aws-s3-cloudfront/module"
  version = "2.0.0"

  website_domain  = "example.com"
  route53_zone_id = <ROUTE53 ZONE ID>

  providers = {
    aws.virginia = aws.n_virginia
  }
}
```

**Create GitHub OpenId Connect**
```hcl
module "website-aws-s3-cloudfront-route53" {
  source  = "eyulf/website-aws-s3-cloudfront/module"
  version = "2.0.0"

  website_domain = "example.com"

  openid_provider_create = true
  github_repo            = "organisation/repo"

  providers = {
    aws.virginia = aws.n_virginia
  }
}
```

**Existing GitHub OpenId Connect**
```hcl
module "website-aws-s3-cloudfront-route53" {
  source  = "eyulf/website-aws-s3-cloudfront/module"
  version = "2.0.0"

  website_domain = "example.com"

  github_openid_arn = "<OPENID CONNECT PROVIDER ARN>"
  github_repo       = "organisation/repo"

  providers = {
    aws.virginia = aws.n_virginia
  }
}
```

---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_aws.virginia"></a> [aws.virginia](#provider\_aws.virginia) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_iam_openid_connect_provider.bitbucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.bitbucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.bitbucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_route53_record.website](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.website_acm_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.website_www](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_cloudfront_cache_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_cloudfront_response_headers_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_iam_policy_document.bitbucket_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.github_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bitbucket_openid_arn"></a> [bitbucket\_openid\_arn](#input\_bitbucket\_openid\_arn) | The ARN for an existing BitBucket OpenID Connect provider. | `string` | `""` | no |
| <a name="input_bitbucket_repo_uuid"></a> [bitbucket\_repo\_uuid](#input\_bitbucket\_repo\_uuid) | A list of Repo UUID's | `string` | `""` | no |
| <a name="input_bitbucket_workspace_name"></a> [bitbucket\_workspace\_name](#input\_bitbucket\_workspace\_name) | The name of the BitBucket workspace. | `string` | `""` | no |
| <a name="input_bitbucket_workspace_uuid"></a> [bitbucket\_workspace\_uuid](#input\_bitbucket\_workspace\_uuid) | BitBucket Workspace UUID. | `string` | `""` | no |
| <a name="input_cloudfront_default_cache_allowed_methods"></a> [cloudfront\_default\_cache\_allowed\_methods](#input\_cloudfront\_default\_cache\_allowed\_methods) | List of allowed methods for the CloudFront default cache behaviour configuration. | `list(string)` | <pre>[<br>  "GET",<br>  "HEAD"<br>]</pre> | no |
| <a name="input_cloudfront_default_cache_cached_methods"></a> [cloudfront\_default\_cache\_cached\_methods](#input\_cloudfront\_default\_cache\_cached\_methods) | List of cached\_methods for the CloudFront default cache behaviour configuration. | `list(string)` | <pre>[<br>  "GET",<br>  "HEAD"<br>]</pre> | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | The price class to use for CloudFront. Must be one of `PriceClass_All`, `PriceClass_200` or `PriceClass_100`. | `string` | `"PriceClass_All"` | no |
| <a name="input_cloudfront_response_headers_policy_name"></a> [cloudfront\_response\_headers\_policy\_name](#input\_cloudfront\_response\_headers\_policy\_name) | The Name of the Response headers policy to use. | `string` | `"Managed-CORS-with-preflight-and-SecurityHeadersPolicy"` | no |
| <a name="input_cloudfront_ssl_minimum_protocol"></a> [cloudfront\_ssl\_minimum\_protocol](#input\_cloudfront\_ssl\_minimum\_protocol) | The minimum SSL protocol to use for the CloudFront viewer certificate configuration. | `string` | `"TLSv1.2_2021"` | no |
| <a name="input_cloudfront_web_acl_arn"></a> [cloudfront\_web\_acl\_arn](#input\_cloudfront\_web\_acl\_arn) | The ARN of an AWS WAF web ACL to associate with CloudFront. | `string` | `""` | no |
| <a name="input_github_openid_arn"></a> [github\_openid\_arn](#input\_github\_openid\_arn) | The ARN for an existing GitHub OpenID Connect provider. | `string` | `""` | no |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | The name of the GitHub repo in the format of 'organisation/repo'. | `string` | `""` | no |
| <a name="input_openid_provider_create"></a> [openid\_provider\_create](#input\_openid\_provider\_create) | Create the OpenID Connect Provider. | `bool` | `false` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | The Route53 Zone ID. If not set DNS records will be returned in outputs. | `string` | `""` | no |
| <a name="input_s3_cors_allowed_headers"></a> [s3\_cors\_allowed\_headers](#input\_s3\_cors\_allowed\_headers) | List of allowed headers for the S3 Bucket's CORS configuration. | `list(string)` | `[]` | no |
| <a name="input_s3_cors_allowed_methods"></a> [s3\_cors\_allowed\_methods](#input\_s3\_cors\_allowed\_methods) | List of allowed methods for the S3 Bucket's CORS configuration. | `list(string)` | <pre>[<br>  "GET"<br>]</pre> | no |
| <a name="input_s3_cors_allowed_origins"></a> [s3\_cors\_allowed\_origins](#input\_s3\_cors\_allowed\_origins) | List of allowed origins for the S3 Bucket's CORS configuration. | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_s3_cors_expose_headers"></a> [s3\_cors\_expose\_headers](#input\_s3\_cors\_expose\_headers) | List of expose headers for the S3 Bucket's CORS configuration. | `list(string)` | `[]` | no |
| <a name="input_s3_lifecycle_noncurrent_expiration"></a> [s3\_lifecycle\_noncurrent\_expiration](#input\_s3\_lifecycle\_noncurrent\_expiration) | The number of days after which a non current version of a S3 object will be expired. | `number` | `30` | no |
| <a name="input_website_aliases"></a> [website\_aliases](#input\_website\_aliases) | Additional domain names to use for the website. | `list(string)` | `[]` | no |
| <a name="input_website_domain"></a> [website\_domain](#input\_website\_domain) | The primary domain name to use for the website. | `string` | n/a | yes |
| <a name="input_website_redirect_www"></a> [website\_redirect\_www](#input\_website\_redirect\_www) | Include www in the Cloudfront Alias and ACM Certificate as well as add code to redirect www to non-www in the Cloudfront Function. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_validation_dns_records"></a> [acm\_validation\_dns\_records](#output\_acm\_validation\_dns\_records) | The DNS records required to validate the ACM Certificate. |
| <a name="output_bitbucket_openid_connect_arn"></a> [bitbucket\_openid\_connect\_arn](#output\_bitbucket\_openid\_connect\_arn) | The ARN of the BitBucket OpenID Connect Provider. |
| <a name="output_bitbucket_openid_connect_role"></a> [bitbucket\_openid\_connect\_role](#output\_bitbucket\_openid\_connect\_role) | The name of the BitBucket OpenID Connect IAM Role. |
| <a name="output_cloudfront_arn"></a> [cloudfront\_arn](#output\_cloudfront\_arn) | The ARN of the Cloudfront Distribution. |
| <a name="output_cloudfront_url"></a> [cloudfront\_url](#output\_cloudfront\_url) | The name of the Cloudfront Distribution's URL. |
| <a name="output_github_openid_connect_arn"></a> [github\_openid\_connect\_arn](#output\_github\_openid\_connect\_arn) | The ARN of the GitHub OpenID Connect Provider. |
| <a name="output_github_openid_connect_role"></a> [github\_openid\_connect\_role](#output\_github\_openid\_connect\_role) | The name of the GitHub OpenID Connect IAM Role. |
| <a name="output_iam_policy_data_json"></a> [iam\_policy\_data\_json](#output\_iam\_policy\_data\_json) | IAM policy data that can be used for S3 uploads and CloudFront invalidation. |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | The name of the S3 Bucket. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
