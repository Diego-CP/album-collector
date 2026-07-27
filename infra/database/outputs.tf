output "cluster_endpoint" {
  value       = aws_rds_cluster.this.endpoint
  description = "Write volume endpoint."
}

output "reader_endpoint" {
  value       = aws_rds_cluster.this.reader_endpoint
  description = "Read (replicas) volume endpoint."
}

output "port" {
  value       = aws_rds_cluster.this.port
  description = "Database port (3306)."
}

output "database_name" {
  value       = aws_rds_cluster.this.database_name
  description = "Initial database name."
}

output "master_user_secret_arn" {
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
  description = "Secrets Manager ARN holding the generated master password."
}

output "security_group_id" {
  value       = aws_security_group.aurora.id
  description = "Aurora security group ID."
}

output "cognito_client_secret_arn" {
  value       = aws_secretsmanager_secret.cognito_client.arn
  description = "ARN of the Cognito client secret (ESO IRSA scope)."
}

output "cognito_client_secret_name" {
  value       = aws_secretsmanager_secret.cognito_client.name
  description = "Name of the Cognito client secret (ExternalSecret remoteRef key)."
}
