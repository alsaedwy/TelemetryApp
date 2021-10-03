# TelemetryApp

## This repository consists of three main parts:

- [TelemetryApp](TelemetryApp) - Python code built using Flask framework, alongside with Dockerfile to containerize the application.
- [Terraform](Terraform) - IaC files in order to provision the necessary resources for the application. Overall it creates a deployment pipeline.

- [Documentation](Documentation)
    - [References](Documentation/References.md) - Main resources I've used during this project.
    - [Steps](Documentation/Steps) - Steps taken (mainly as a reference for myself) in order to reach the last commit.
    - [Improvements](Documentation/Improvements.md) - Ideas that come to my mind and will improve either the application's code, the IaC, or both.


## About the application files ([TelemetryApp](TelemetryApp)):

- Consists of [main.py](TelemetryApp/main.py) and [requirements.txt](TelemetryApp/requirements.txt), alongside a [Dockerfile](TelemetryApp/Dockerfile).
- `main.py` has all of the code needed for the both APIs (PUT -> /api/temperature) and (GET -> /api/stats). An extra /api with GET method was added for healthchecks outside database operations.
- `requirements.txt` has all the dependencies needed for the application (mainly `Boto3` and `Flask`). 
- The Dockerfile copies the application's files, installs the requirements in `requirements.txt`, and passes 4 main arguments `TABLE_NAME`, `AWS_DEFAULT_REGION`, `FLASK_ENV`, `FLASK_APP` to the image during the build stage, which the application reads from the container image afterwards. Only `FLASK_APP` is hardcoded, since the value (`main.py`) is known beforehand, all other arguments can be overriden during either building or running the container. The base layer is `python:3-alpine`.

## About [Terraform](Terraform) files; a tear down:

- [main.tf](Terraform/main.tf) - Only contains the provider, AWS.
- [vars.tf](Terraform/vars.tf) - Has some variables used within the Terraform files.
- [rolesandpermissions.tf](Terraform/rolesandpermissions.tf) - Contains all of the roles associated with the provisioned resources.
- [codepipeline.tf](Terraform/codepipeline.tf) - Creates a pipeline that pulls the code after being triggered from CodeCommit, builds the container using CodeBuild, pushes the image to an ECR repository, then deploys the ECR image to an ECS service. Below are the main stages:
  - [repos.tf](Terraform/repos.tf) - Creates a CodeCommit -empty- repository, and an ECR repository, the CodeCommit repository is used for the `Source` stage in the pipeline
  - [codebuild.tf](Terraform/codebuild.tf) - Creates a CodeBuild project, used with `Build` stage.
  - [ecs.tf](Terraform/ecs.tf) - Creates an ECS cluster, a task definition, and an ECS service, used with `Deploy` stage.
- [vpc.tf](Terraform/vpc.tf) - Creates a VPC with `10.0.0.0/16` CIDR, 3 public subnets `10.0.101.0/24`, `10.0.102.0/24`, and `10.0.103.0/24`. It also creates an Internet Gateway, and a security group with inbound rules for ports `80` and `22` from any address.
