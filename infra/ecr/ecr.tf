resource "aws_ecr_repository" "app" {
  name                 = var.project
  image_tag_mutability = var.image_tag_mutability

  # Scan pushed images for known CVEs automatically
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # Failsafe if images are present in the repo
  force_delete = false

  tags = { Name = var.project }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      },
      {
        # tagStatus = "any" must have the lowest priority
        rulePriority = 2
        description  = "Keep only the most recent 10 images total"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
