resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-aurora"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  tags       = { Name = "${var.project}-aurora-subnet-group" }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.project}-aurora"
  engine             = "aurora-mysql"

  # Serverless v2 runs in "provisioned" mode
  engine_mode    = "provisioned"
  engine_version = var.engine_version

  database_name   = var.database_name
  master_username = var.master_username

  # RDS-managed master password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
    seconds_until_auto_pause = var.seconds_until_auto_pause
  }

  storage_encrypted       = true
  backup_retention_period = 1

  # TODO: Flip in prod
  skip_final_snapshot = true
  deletion_protection = false
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${var.project}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  instance_class      = "db.serverless"
  publicly_accessible = false
}
