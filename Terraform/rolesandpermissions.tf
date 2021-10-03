# CodeBuild Role
resource "aws_iam_role" "CodeBuild-Telemetry-Role-2" {
  name = "CodeBuild-Telemetry-Role-2"

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

# IAM Role for CodePipeline 
resource "aws_iam_role" "codepipeline-telemetryapp-role" {
  name = "codepipeline-telemetryapp-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodePipelineFullAccess","arn:aws:iam::aws:policy/AWSCodeCommitPowerUser","arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"]
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
        "codebuild:StartBuild",
        "codecommit:*",
        "ecs:*",
        "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}



## ECS Task execution role 
resource "aws_iam_role"  "TaskDefinition-Telemetry-Execution-Role" {
  name = "Telemetry-Task-Execution-Role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy","arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]

  inline_policy {
    name = "AllowECR"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ecr:*","dynamodb:*"]
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
