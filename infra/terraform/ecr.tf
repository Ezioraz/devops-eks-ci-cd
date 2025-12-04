resource "aws_ecr_repository" "app_repo" {
  name = "${var.project_name}-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}
