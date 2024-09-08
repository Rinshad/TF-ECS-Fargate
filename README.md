# TF-ECS-Fargate
Terraform code is used to provide complete infrastructure to host the "Notejam" application.

# Architecture diagram

![Notejam_app](https://github.com/user-attachments/assets/f9c4dfb0-45d3-4d0b-8e24-c00efd8692be)


# AWS Resource.
Terraform (Iac approach) was used to provision the AWS ECS cluster. The code provisioned the following resources. The same code can be used to provision resources for similar application hosting by changing the variables in the terraform *.tfvars file.

1. VPC, private and public subnet. 
2. Route tables, Internet gateways, Security group and NAT gateway.
3. ECS Fargate cluster with service and task definition.
4. Application Loadblancer, to access the ECS cluster application.
5. RDS database, with access limited from the private subnet.
6. ECR to host application images.
7. AWS IAM roles for ECS task execution and RDS access.

# Infrastructure security.
The application hosted on ECS Fargate can be accessed only using the Application Gateway DNS name. The Security group attached restricts incoming connection only to port 80 (with TLS/SSL certificate can be used to make it more secure). The ECS Fargate and RDS are provisioned under the private subnet and can't be accessed directly from the internet.

The ECS cluster and RDS cluster is highly available, currently provisioned in the eu-central-1a and eu-central-1b availability zone. The availability zone can be increased by modifying the az_count variable.

# Application deployment.

The Notejam (Express js framework)  application is containerized. The build and deployment are handled with GitHub Actions Workflow. The application image will be pushed to AWS ECR and pulled by the ECS cluster to host the application. The build pipeline creates the ECS task definition and pushes it to the ECS Fargate cluster.

Any changes to the application can be made using the Gitops method. (Git is considered the source of truth.) To make changes to the application clone the repository and make changes to a new branch. Pushing to master will automatically trigger the application build and deployment Github Actions.

# Github action workflow code
```
---
name: Build and Push Docker Image to AWS ECR
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      - name: Login to AWS ECR
        run: >
          aws ecr get-login-password --region ${{ secrets.AWS_REGION }} | docker
          login --username AWS --password-stdin ${{ secrets.ECR_URI }}
      - name: Build Docker image
        run: |
          docker build -t ${{ secrets.ECR_URI }}:latest .
      - name: Push to AWS ECR
        run: |
          docker push ${{ secrets.ECR_URI }}:latest
      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: notejam-app-task.json
          service: notejam-service
          cluster: notejam-cluster
          region: $AWS_REGION
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```






