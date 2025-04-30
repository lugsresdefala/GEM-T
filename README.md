# GEM-T

## Deployment Instructions

### Deploying the Application using Docker

1. **Build the Docker image:**
   ```sh
   docker build -t myapp:latest .
   ```

2. **Run the Docker container:**
   ```sh
   docker run -p 5000:5000 myapp:latest
   ```

### Setting up the CI/CD Pipeline

1. **Create a GitHub Actions workflow file:**
   - Add a `.github/workflows/ci-cd.yml` file with the following content:
     ```yaml
     name: CI/CD Pipeline

     on:
       push:
         branches:
           - main
       pull_request:
         branches:
           - main

     jobs:
       build:
         runs-on: ubuntu-latest

         steps:
           - name: Checkout code
             uses: actions/checkout@v2

           - name: Set up Docker Buildx
             uses: docker/setup-buildx-action@v1

           - name: Cache Docker layers
             uses: actions/cache@v2
             with:
               path: /tmp/.buildx-cache
               key: ${{ runner.os }}-buildx-${{ github.sha }}
               restore-keys: |
                 ${{ runner.os }}-buildx-

           - name: Build Docker image
             run: docker build --tag myapp:latest .

           - name: Push Docker image to GitHub Container Registry
             run: |
               echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
               docker tag myapp:latest ghcr.io/${{ github.repository }}/myapp:latest
               docker push ghcr.io/${{ github.repository }}/myapp:latest

       test:
         runs-on: ubuntu-latest
         needs: build

         steps:
           - name: Checkout code
             uses: actions/checkout@v2

           - name: Run tests
             run: docker run --rm myapp:latest pytest

       deploy:
         runs-on: ubuntu-latest
         needs: test

         steps:
           - name: Checkout code
             uses: actions/checkout@v2

           - name: Deploy to AWS Elastic Beanstalk
             env:
               AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
               AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
               AWS_REGION: ${{ secrets.AWS_REGION }}
             run: |
               docker tag myapp:latest ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/myapp:latest
               docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/myapp:latest
               eb init -p docker myapp --region ${{ secrets.AWS_REGION }}
               eb create myapp-env
               eb deploy
     ```

### Deploying the Application to AWS using Terraform

1. **Create a Terraform configuration file:**
   - Add a `terraform/main.tf` file with the following content:
     ```hcl
     provider "aws" {
       region = var.aws_region
     }

     resource "aws_elastic_beanstalk_application" "myapp" {
       name        = "myapp"
       description = "Elastic Beanstalk Application for myapp"
     }

     resource "aws_elastic_beanstalk_environment" "myapp_env" {
       name                = "myapp-env"
       application         = aws_elastic_beanstalk_application.myapp.name
       solution_stack_name = "64bit Amazon Linux 2 v3.1.2 running Docker"

       setting {
         namespace = "aws:elasticbeanstalk:application:environment"
         name      = "DOCKER_IMAGE"
         value     = "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/myapp:latest"
       }
     }

     resource "aws_iam_instance_profile" "myapp_instance_profile" {
       name = "myapp-instance-profile"

       role {
         name = "myapp-role"
       }
     }

     resource "aws_iam_role" "myapp_role" {
       name = "myapp-role"

       assume_role_policy = jsonencode({
         Version = "2012-10-17"
         Statement = [
           {
             Action = "sts:AssumeRole"
             Effect = "Allow"
             Principal = {
               Service = "ec2.amazonaws.com"
             }
           }
         ]
       })
     }

     resource "aws_iam_role_policy_attachment" "myapp_role_policy_attachment" {
       role       = aws_iam_role.myapp_role.name
       policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
     }

     resource "aws_ecr_repository" "myapp_ecr" {
       name = "myapp"
     }

     output "elastic_beanstalk_application_name" {
       value = aws_elastic_beanstalk_application.myapp.name
     }

     output "elastic_beanstalk_environment_name" {
       value = aws_elastic_beanstalk_environment.myapp_env.name
     }

     output "ecr_repository_url" {
       value = aws_ecr_repository.myapp_ecr.repository_url
     }
     ```

2. **Initialize and apply the Terraform configuration:**
   ```sh
   cd terraform
   terraform init
   terraform apply
   ```
