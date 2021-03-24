# Terraform AWS S3/Cloudfront Website

## Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction

This module will configure multiple S3 buckets with website hosting enabled. Cloudflare is used for DNS hosting. An IAM user is also created and configured with an intial access key to provide an easy way to upload website files to the S3 buckets.

A bucket is created for the provided domain plus bucket for redirects to this.

Cloudfront is configured to serve SSL certificates that are generated by ACM. A Lambda application[1] is also provisioned to work around limitations[2] with Cloudfront's Origin Access Identity and S3 website hosting. Route 53 is used for DNS hosting and a Route53 zone will be created and configured.

This _may_ cost less then approximately USD$0.12 per month for a website with very minimal traffic.

1. https://github.com/digital-sailors/standard-redirects-for-cloudfront
1. https://aws.amazon.com/blogs/compute/implementing-default-directory-indexes-in-amazon-s3-backed-amazon-cloudfront-origins-using-lambdaedge/

## Usage

### Default
```hcl
module "static_website_aws_cloudflare" {
  source             = "path/to/module"
  domain             = "example.com"
  cloudflare_zone_id = <CLOUDFLARE ZONE ID>
}
```

### No IAM users or groups created
```hcl
module "static_website_aws_cloudflare" {
  source             = "path/to/module"
  domain             = "example.com"
  cloudflare_zone_id = <CLOUDFLARE ZONE ID>
  create_iam_user    = false
  create_iam_group   = false
}
```

### Use existing group
```hcl
module "static_website_aws_cloudflare" {
  source             = "path/to/module"
  domain             = "example.com"
  cloudflare_zone_id = <CLOUDFLARE ZONE ID>
  create_iam_group   = false
}
```

Note: This expects the group to already exist as it will create the user and attempt to add it to the group.

---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
Provider Configuration

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | ~> 3.0 |
| cloudflare | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |
| aws.virginia | ~> 3.0 |
| cloudflare | ~> 2.0 |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_acm_certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/acm_certificate_validation) |
| [aws_acm_certificate](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/acm_certificate) |
| [aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/cloudfront_distribution) |
| [aws_cloudfront_origin_access_identity](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/cloudfront_origin_access_identity) |
| [aws_iam_access_key](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/iam_access_key) |
| [aws_iam_group](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/data-sources/iam_group) |
| [aws_iam_group](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/iam_group) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/data-sources/iam_policy_document) |
| [aws_iam_user_group_membership](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/iam_user_group_membership) |
| [aws_iam_user_policy](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/iam_user_policy) |
| [aws_iam_user](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/iam_user) |
| [aws_s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/s3_bucket_policy) |
| [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/s3_bucket) |
| [aws_serverlessapplicationrepository_application](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/data-sources/serverlessapplicationrepository_application) |
| [aws_serverlessapplicationrepository_cloudformation_stack](https://registry.terraform.io/providers/hashicorp/aws/3.0/docs/resources/serverlessapplicationrepository_cloudformation_stack) |
| [cloudflare_record](https://registry.terraform.io/providers/cloudflare/cloudflare/2.0/docs/resources/record) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudflare\_zone\_id | The Cloudflare Zone ID. | `string` | n/a | yes |
| create\_iam\_group | Toggle creating a IAM user for S3 uploads. | `bool` | `true` | no |
| create\_iam\_user | Toggle creating a IAM user for S3 uploads. | `bool` | `true` | no |
| domain | The domain to use. | `string` | n/a | yes |
| s3\_cors\_allowed\_origins | Specifies which origins are allowed for the S3 CORS configuration. | `list(string)` | `[]` | no |
| user\_group | The IAM group to add the S3 Uploader user. | `string` | `"s3_Uploaders"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudfront\_url | The name of the Cloudfront URL. |
| cloudfront\_url\_redirect | The name of the Cloudfront URL providing redirects. |
| iam\_user\_access\_key\_id | The Access Key ID of the IAM user used for uploading to the S3 bucket |
| iam\_user\_secret\_access\_key | The Secret Access Key of the IAM user used for uploading to the S3 bucket |
| s3\_bucket | The name of the S3 Bucket |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
