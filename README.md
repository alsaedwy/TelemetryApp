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
  - [codebuild.tf](Terraform/codebuild.tf) - Creates a CodeBuild project, used with `Build` stage. [buildspec.yml](Terraform/buildspec.yml) is included in the same directory as well as it is read from the Terraform file for CodeBuild.
  - [ecs.tf](Terraform/ecs.tf) - Creates an ECS cluster, a task definition, and an ECS service, used with `Deploy` stage.
- [vpc.tf](Terraform/vpc.tf) - Creates a VPC with `10.0.0.0/16` CIDR, 3 public subnets `10.0.101.0/24`, `10.0.102.0/24`, and `10.0.103.0/24`. It also creates an Internet Gateway, and a security group with inbound rules for ports `80` and `22` from any address.
- [dynamodb.tf](Terraform/dynamodb.tf] - Creates a DynamoDB table with a primary key `time`. 
- [loadbalancer.tf](Terraform/dynamodb.tf) - Creates an Application Loadbalancer, with a target group for the ECS tasks.
- [outputs.tf](Terraform/outputs.tf) - Outputs 3 main URLs: CodeCommit Repository, and an endpoint URL for the ALB. This URL can be used for communicating with the application after the first deployment (explained below), after adding requested paths (`/api/temperature` and `/api/stats`).

![Telemetry App Challenge](https://user-images.githubusercontent.com/14993988/135810782-df75f97d-5d76-47e7-a075-06bce8bf2bf2.jpg)


## First deployment:

### Prerequisits: 
- An AWS user with sufficient permissions to create all of the above resources and roles.
- A shell terminal with configured access keys.

### Steps for deployment:

1. Clone the repository using `git clone https://github.com/alsaedwy/TelemetryApp`, then change into the Terraform directory using `cd TelemetryApp/Terraform`.
2. Initiate Terraform to download the provider files `terraform init`.
3. Apply the Terraform code with `terraform apply`. 
4. Terraform will output 2 URLs after a successful deployment. Please take copy these URLs for usage within next steps.
5. *IMPORTANT STEP* - Since the CodeCommit repository is empty, you will need to push the code (from your terminal).
    1. Create a CodeCommit user credentials for a user with [sufficient permissions](https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-permissions-reference.html#aa-git) to push code to the newly created and empty repository. 
    2. The pushed code _*has to be*_ a clone from this repository. So a `tree` command will look like this locally when pushing the repository. This is important and it will affect how the pipeline works in further steps (because of the file references).

            ├── Documentation
            │   ├── Improvements.md
            │   ├── References.md
            │   └── Steps.md
            ├── LICENSE
            ├── README.md
            ├── TelemetryApp
            │   ├── Dockerfile
            │   ├── main.py
            │   └── requirements.txt
            └── Terraform
                ├── buildspec.yml
                ├── codebuild.tf
                ├── codepipeline.tf
                ├── dynamodb.tf
                ├── ecs.tf
                ├── loadbalancer.tf
                ├── main.tf
                ├── outputs.tf
                ├── repos.tf
                ├── rolesandpermissions.tf
                ├── terraform.tfstate
                ├── terraform.tfstate.backup
                ├── vars.tf
                └── vpc.tf

    3. You will need to use the username and password to push the code for the CodeCommit repository in your account. 
    4. For a detailed steps regarding this step, please have a look [here](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-migrate-repository-existing.html). 
6. After the first push, a deployment will be triggered on the pipeline, and after a success in the 3 stages, you should be able to reach the endpoint with `/api`, `/api/temperature` using PUT method, and `/api/stats` using GET method. 

----------------------------
## Usage:
- Using `PUT` method with _`endpoint-URL`_`/api/temperature`, a payload can be a JSON like the following:
```
    {
     "sensorID": "107",
     "temperature": "12",
     "time": "2021-10-04 09:00:00"
    }
```
A sucessful response will be `Ok` with response code `200`.

- Using `GET` method with  _`endpoint-URL`_`/api/temperature`, a sucessful response will be similar to the following:
```
    {
     "Average": 12,
     "Maximum": 12,
     "Minimum": 12
    }
```
