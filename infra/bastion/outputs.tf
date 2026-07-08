output "bastion_instance_id" {
  value       = aws_instance.bastion.id
  description = "Target id for `aws ssm start-session`."
}
