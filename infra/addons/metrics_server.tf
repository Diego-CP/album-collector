resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_chart_version

  set = [
    # EKS doesn't issue kubelet serving certs that metrics-server trusts, so 
    # scraping fails with a TLS error and HPA shows CPU as <unknown>. This 
    # skips that verification
    # TODO: Enable kubelet serving-cert signing instead
    { name = "args[0]", value = "--kubelet-insecure-tls" },
  ]
}
