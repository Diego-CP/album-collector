# Container for the Cognito app client secret
resource "aws_secretsmanager_secret" "cognito_client" {
  name = "${var.project}/cognito-client-secret"
}
