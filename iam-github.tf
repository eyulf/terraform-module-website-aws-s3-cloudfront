### OpenID

resource "aws_iam_openid_connect_provider" "github" {
  count = var.openid_provider_create && var.github_repo != "" ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  thumbprint_list = [
    "f879abce0008e4eb126e0097e46620f5aaae26ad", # token.actions.githubusercontent.com (04/02/2023)
  ]
}

### IAM Role

resource "aws_iam_role" "github" {
  count = var.github_repo != "" ? 1 : 0

  name               = "OpenIdGitHub-${replace(var.website_domain, ".", "-")}"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    sid     = "AllowRoleAssumptionWithWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.openid_provider_create && var.github_openid_arn == "" ? aws_iam_openid_connect_provider.github[0].arn : var.github_openid_arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

### IAM Policy

resource "aws_iam_role_policy" "github" {
  count = var.github_repo != "" ? 1 : 0

  name   = "OpenIdGitHub"
  role   = aws_iam_role.github[0].id
  policy = data.aws_iam_policy_document.pipeline.json
}
