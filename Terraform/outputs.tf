output "CodeCommit-RepositoryURL" {
  value = aws_codecommit_repository.TelemetryApp-CC-Repo.clone_url_http
}
output "ALB-URL-ENDPOINT" {
  value = aws_lb.Telemetry-ALB-For-ECS-Service.dns_name
}