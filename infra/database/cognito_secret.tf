# Container for the Cognito app client secret
resource "aws_secretsmanager_secret" "cognito_client" {
  name = "${var.project}/cognito-client-secret"

  # No recovery window blocking a delete/recreate
  # Would use default in prod
  recovery_window_in_days = 0
}
