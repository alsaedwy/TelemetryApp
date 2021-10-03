# Steps:

## Code 

1- Create the APIs locally using dictionaries, and create the logic to return max, min and average temperatures. - Done.

2- Add DynamoDB connection with inserting the data into the table(s) instead of local dictionaries. - Done.

3- Query the DynamoDB table for stats, instead of local dictionary. - Done. 

4- Make 'Table Name' a variable, so that the code can dynamically work with any table. - Done.

5- Containerise the application. - Done.
-----------------------------------------
## Infrastructure and Deployment

6- Create a high level diagram (use draw.io). 

7- Create CodeBuild Project using Terraform. - Done.
-- CodeBuild permissions (create policy) for ECR 
-- Make sure it is priviliged mode

8- Create an AWS pipeline to build and deploy the application after each push. - Done.

9- Create required repositories, ECS cluster and a VPC. - Done.

10- Write documentation for the project.