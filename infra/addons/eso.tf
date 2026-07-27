# IRSA role for ESO controller scoped to the two secrets
module "eso_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                      = "${var.project}-external-secrets"
  attach_external_secrets_policy = true
  external_secrets_secrets_manager_arns = [
    data.terraform_remote_state.database.outputs.master_user_secret_arn,
    data.terraform_remote_state.database.outputs.cognito_client_secret_arn,
  ]

  oidc_providers = {
    main = {
      provider_arn               = data.terraform_remote_state.eks.outputs.cluster_oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}

resource "helm_release" "eso" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = var.eso_chart_version

  set = [
    # Install the Custom Resource Definitions
    { name = "installCRDs", value = "true" },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "external-secrets" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = module.eso_irsa.iam_role_arn },
  ]

  # Wait for LB controller to register the webhook
  depends_on = [helm_release.lbc]
}
