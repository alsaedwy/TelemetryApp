# Create empty repository to host the code later 
resource "aws_codecommit_repository" "TelemetryApp-CC-Repo" {
  repository_name = "TelemetryApp"
  description     = "Repository to upload Alaa's Telemetry App To"
  default_branch = "main"
}

# Create empty ECR repository
resource "aws_ecr_repository" "TelemetryAppECRRepo" {
  name = "telemetryapp"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}