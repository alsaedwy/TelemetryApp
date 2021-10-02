provider "aws" {
    region = "eu-west-1"
}

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

# VPC for ECS
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Telemetry-VPC"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  create_igw = "true"
  manage_default_security_group = "true"
  default_route_table_routes = [{"0.0.0.0/0": module.vpc.public_internet_gateway_route_id}]
  default_security_group_ingress = [
    {
      "description": "HTTP from the Internet"
      "from_port": "80"
      "to_port" : "80"
      "protocol": "tcp"
      "cidr_blocks": "0.0.0.0/0"
      "ipv6_cidr_blocks": "::/0"
    },
        {
      "description": "SSH from the Internet"
      "from_port": "22"
      "to_port" : "22"
      "protocol": "tcp"
      "cidr_blocks": "0.0.0.0/0"
      "ipv6_cidr_blocks": "::/0"
    }
  ]
default_security_group_egress = [
    {
      "from_port"        : "0"
      "to_port"          : "0"
      "protocol"         : "-1"
      "cidr_blocks"      : "0.0.0.0/0"
      "ipv6_cidr_blocks" : "::/0"
    }
  ]

}

# CodeBuild Role
resource "aws_iam_role" "CodeBuild-Telemetry-Role-2" {
  name = "CodeBuild-Telemetry-Role-2"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })


}

# CodeBuild policy for the role
resource "aws_iam_role_policy" "CodeBuild-Telemetry-Policy" {
  role = aws_iam_role.CodeBuild-Telemetry-Role-2.name

  policy = <<POLICY
{
	"Version": "2012-10-17",
	"Statement": [{
			"Effect": "Allow",
			"Resource": [
				"*"
			],
			"Action": [
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
                "logs:*",
				"ec2:CreateNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
				"ec2:DescribeDhcpOptions",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DeleteNetworkInterface",
				"ec2:DescribeSubnets",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeVpcs",
				"ecr:BatchCheckLayerAvailability",
				"ecr:CompleteLayerUpload",
				"ecr:GetAuthorizationToken",
				"ecr:InitiateLayerUpload",
				"ecr:PutImage",
				"ecr:UploadLayerPart",
        "s3:*"
			],
			"Resource": "*"
		}
	]
}
POLICY
}



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
 #   location        = "https://github.com/alsaedwy/TelemetryApp"
    git_clone_depth = 0
    # This next line took a considerable amount of time to work :) 
    buildspec = templatefile("buildspec.yml", {ECRREPO = aws_ecr_repository.TelemetryAppECRRepo.repository_url} )
    


  }

}

#CodePipeline 
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
}

resource "aws_iam_role" "codepipeline-telemetryapp-role" {
  name = "test-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodePipelineFullAccess","arn:aws:iam::aws:policy/AWSCodeCommitPowerUser"]
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


# Role and Policy for CodePipeline
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline-telemetryapp-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket-telemetry.arn}",
        "${aws_s3_bucket.codepipeline_bucket-telemetry.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_cloudwatch_log_group" "ECS_Telemetry_Logging" {
  name = "example"
}

resource "aws_ecs_cluster" "Telemetry_Cluster" {
  name = "Telemetry_Cluster"

  configuration {
    execute_command_configuration {
      
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ECS_Telemetry_Logging.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "TaskDefinition-Telemetry" {
  family = "TelemetryTaskDefinition"
  execution_role_arn = aws_iam_role.TaskDefinition-Telemetry-Execution-Role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  container_definitions = jsonencode([
    {
      name      = "TelemetryApp"
      image     = "${aws_ecr_repository.TelemetryAppECRRepo.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

## ECS Task role to pull container
resource "aws_iam_role"  "TaskDefinition-Telemetry-Execution-Role" {
  name = "CodeBuild-Telemetry-Role-2-2"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  inline_policy {
    name = "AllowECR"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ecr:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
    assume_role_policy = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
POLICY
}


# resource "aws_iam_role_policy_attachment" "AttachExistingPolicyToExecutionRole" {
#   role       = aws_iam_role.TaskDefinition-Telemetry-Execution-Role.name
#   policy_arn = aws_iam_role_policy.CodeBuild-Telemetry-Policy.role_arn
# }


resource "aws_ecs_service" "TelemetryECSService" {
  name    = "TelemetryECSService"
  cluster = aws_ecs_cluster.Telemetry_Cluster.id
  launch_type = "FARGATE"
  desired_count = 2
  # deployment_controller {
  #   type = "CODE_DEPLOY"
  # }
  task_definition = aws_ecs_task_definition.TaskDefinition-Telemetry.arn
  network_configuration {
    subnets = [module.vpc.public_subnets[0],module.vpc.public_subnets[0],module.vpc.public_subnets[0]]
    security_groups = [module.vpc.default_security_group_id]
    assign_public_ip = "true"

  }
}


output "OutPutECR" {
  value = aws_ecr_repository.TelemetryAppECRRepo.repository_url
}


output "CodeCommit" {
  value = aws_codecommit_repository.TelemetryApp-CC-Repo.clone_url_http
}

