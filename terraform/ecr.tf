# Create ECR
resource "aws_ecr_repository" "tornado_webapp" {
  name = "tornado-webapp"
}