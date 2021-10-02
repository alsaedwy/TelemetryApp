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

# VPC for CodeBuild and ECS
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
resource "aws_iam_role" "CodeBuild-Telemetry-Role" {
  name = "CodeBuild-Telemetry-Role"

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
  role = aws_iam_role.CodeBuild-Telemetry-Role.name

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
				"ecr:UploadLayerPart"
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
  service_role  = aws_iam_role.CodeBuild-Telemetry-Role.arn

  artifacts {
    type = "NO_ARTIFACTS"
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
    type            = "GITHUB"
    location        = "https://github.com/alsaedwy/TelemetryApp"
    git_clone_depth = 0


  }


#   vpc_config {
#     vpc_id = module.vpc.vpc_id

#     subnets = [
#       module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]
#     ]

#     security_group_ids = [
#       module.vpc.default_security_group_id
#     ]
#   }

}












