# IRSA role scoped to this cluster's ASGs
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "${var.project}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [data.terraform_remote_state.eks.outputs.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = data.terraform_remote_state.eks.outputs.cluster_oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.cluster_autoscaler_chart_version

  set = [
    # Autoscaler finds node group's ASG by the k8s.io/cluster-autoscaler tag
    { name = "autoDiscovery.clusterName", value = data.terraform_remote_state.eks.outputs.cluster_name },
    { name = "awsRegion", value = var.region },

    { name = "rbac.serviceAccount.name", value = "cluster-autoscaler" },
    { name = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = module.cluster_autoscaler_irsa.iam_role_arn },

    # Match cluster's version
    { name = "image.tag", value = "v1.33.6" },
  ]

  # Wait for LB controller to register the webhook
  depends_on = [helm_release.lbc]
}
