data "aws_caller_identity" "current" {}

# GitHub's OIDC identity provider
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Only GitHub and only my repo may assume this role
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # any branch/ref in this repo
      values = ["repo:${var.github_owner}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

locals {
  ecr_repo_arn    = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project}"
  eks_cluster_arn = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project}-eks"
}

# Permissions to push to the app's ECR repo and read the cluster's connection info
data "aws_iam_policy_document" "permissions" {
  statement {
    sid       = "EcrAuthToken"
    actions   = ["ecr:GetAuthorizationToken"] # account-wide; can't be resource-scoped
    resources = ["*"]
  }
  statement {
    sid = "EcrPushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [local.ecr_repo_arn]
  }
  statement {
    sid       = "EksDescribe"
    actions   = ["eks:DescribeCluster"] # enough to build a kubeconfig
    resources = [local.eks_cluster_arn]
  }
}

resource "aws_iam_role_policy" "permissions" {
  name   = "ci-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.permissions.json
}
