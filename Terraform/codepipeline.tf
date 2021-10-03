# CodePipeline Stage
resource "aws_codepipeline" "codepipeline-telemetryapp" {
  name     = "codepipeline-telemetryapp"
  role_arn = aws_iam_role.codepipeline-telemetryapp-role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket-telemetry.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.TelemetryApp-CC-Repo.repository_name
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.Telemetry-CB-Project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.Telemetry_Cluster.name
        ServiceName = aws_ecs_service.TelemetryECSService.name
      
      }
    }
  }
}


resource "aws_s3_bucket" "codepipeline_bucket-telemetry" {
  bucket = "telemetry-bucket-alaa"
  acl    = "private"
  force_destroy = "true"
}