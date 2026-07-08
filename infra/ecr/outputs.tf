# This stack's state key: "ecr/terraform.tfstate"

output "repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "Full registry path to tag and push to (account.dkr.ecr.region.amazonaws.com/name)."
}

output "repository_name" {
  value       = aws_ecr_repository.app.name
  description = "Repository name."
}

output "repository_arn" {
  value       = aws_ecr_repository.app.arn
  description = "Repository ARN."
}
