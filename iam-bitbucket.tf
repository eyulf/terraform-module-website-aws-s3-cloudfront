### OpenID

resource "aws_iam_openid_connect_provider" "bitbucket" {
  count = var.openid_provider_create && var.bitbucket_repo_uuid != "" ? 1 : 0

  url            = "https://api.bitbucket.org/2.0/workspaces/${var.bitbucket_workspace_name}/pipelines-config/identity/oidc"
  client_id_list = ["ari:cloud:bitbucket::workspace/${var.bitbucket_workspace_uuid}"]

  # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  thumbprint_list = [
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e", # api.bitbucket.org (04/02/2023)
  ]
}

### IAM Role

resource "aws_iam_role" "bitbucket" {
  count = var.bitbucket_repo_uuid != "" ? 1 : 0

  name               = "OpenIdBitBucket-${replace(var.website_domain, ".", "-")}"
  assume_role_policy = data.aws_iam_policy_document.bitbucket_assume.json
}

data "aws_iam_policy_document" "bitbucket_assume" {
  statement {
    sid     = "AllowRoleAssumptionWithWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.openid_provider_create && var.bitbucket_openid_arn == "" ? aws_iam_openid_connect_provider.bitbucket[0].arn : var.bitbucket_openid_arn]
    }

    condition {
      test     = "StringLike"
      variable = "api.bitbucket.org/2.0/workspaces/${var.bitbucket_workspace_name}/pipelines-config/identity/oidc:sub"
      values   = ["${var.bitbucket_repo_uuid}:*"]
    }
  }
}

### IAM Policy

resource "aws_iam_role_policy" "bitbucket" {
  count = var.bitbucket_repo_uuid != "" ? 1 : 0

  name   = "OpenIdBitBucket"
  role   = aws_iam_role.bitbucket[0].id
  policy = data.aws_iam_policy_document.pipeline.json
}
