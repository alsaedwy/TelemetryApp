# CodeBuild Project
resource "aws_codebuild_project" "Telemetry-CB-Project" {

  name          = "Telemetry-CB-Project"
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.CodeBuild-Telemetry-Role-2.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = "true"


  }

  logs_config {
    cloudwatch_logs {
      group_name  = "CB-Telemetry-log-group"
      stream_name = "CB-Telemetry-log-stream"
    }
  }

  source {
    type            = "CODEPIPELINE"
    git_clone_depth = 0
    buildspec = templatefile(
    "buildspec.yml",
    {ECRREPO = aws_ecr_repository.TelemetryAppECRRepo.repository_url, 
     REGION = var.region,
     TABLE_NAME = aws_dynamodb_table.Telemetry-dynamodb-table.name,
     FLASK_ENV = var.FLASK_ENV
    } )

  }

}

resource "aws_cloudwatch_log_group" "ECS_Telemetry_Logging" {
  name = "ECS_Telemetry_Logging"
}