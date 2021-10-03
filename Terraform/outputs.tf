<<<<<<< HEAD
output "ECR-Repo-URL" {
=======
output "ECR-Repo-URL" {
>>>>>>> 33ddeb7fce0f64e7f38696f1c9c187a40cca82d6
  value = aws_ecr_repository.TelemetryAppECRRepo.repository_url
}


output "CodeCommit-RepositoryURL" {
  value = aws_codecommit_repository.TelemetryApp-CC-Repo.clone_url_http
}
output "ALB-URL-ENDPOINT" {
  value = aws_lb.Telemetry-ALB-For-ECS-Service.dns_name
}