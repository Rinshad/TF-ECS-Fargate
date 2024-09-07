resource "aws_ecr_repository" "my_repository" {
  name = "${var.app_prefix}"
}

output "repository_url" {
  value = aws_ecr_repository.my_repository.repository_url
}
