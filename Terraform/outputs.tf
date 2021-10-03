output "OutPutECR" {
  value = aws_ecr_repository.TelemetryAppECRRepo.repository_url
}


output "CodeCommit" {
  value = aws_codecommit_repository.TelemetryApp-CC-Repo.clone_url_http
}
output "ALB-URL" {
  value = aws_lb.Telemetry-ALB-For-ECS-Service.dns_name
}