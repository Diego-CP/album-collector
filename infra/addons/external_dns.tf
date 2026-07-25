# IRSA role scoped to hosted zone. The module's external-dns preset grants
# route53:ChangeResourceRecordSets on the given zone plus the List* it needs
module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                     = "${var.project}-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${data.terraform_remote_state.dns.outputs.zone_id}"]

  oidc_providers = {
    main = {
      provider_arn               = data.terraform_remote_state.eks.outputs.cluster_oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = var.external_dns_chart_version

  set = [
    { name = "provider.name", value = "aws" },

    # Sync lets it CREATE, UPDATE, and DELETE records it owns
    { name = "policy", value = "sync" },

    { name = "domainFilters[0]", value = data.terraform_remote_state.dns.outputs.domain_name },
    { name = "sources[0]", value = "ingress" },

    # txtOwnerId is stable, so ExternalDNS still recognizes the ownership records after rebuilding
    { name = "txtOwnerId", value = var.project },
    { name = "txtPrefix", value = "extdns-" }, # avoids TXT/ALIAS name collision at the apex

    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "external-dns" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = module.external_dns_irsa.iam_role_arn },
  ]
}
