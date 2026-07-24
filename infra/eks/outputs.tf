output "cluster_name" {
  value       = module.eks.cluster_name
  description = "For: aws eks update-kubeconfig --name <this>."
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Kubernetes API endpoint."
}

output "cluster_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN. Needed for IRSA roles (LB controller, autoscaler, etc.)."
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Cluster security group id."
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Node security group id."
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Cluster CA (base64)."
  sensitive   = true
}
