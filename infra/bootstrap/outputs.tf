output "state_bucket_name" {
  value       = aws_s3_bucket.tf_state.id
  description = "Bucket name for the backend block - it can't use variables."
}

output "region" {
  value       = var.region
  description = "Region for the backend block."
}
