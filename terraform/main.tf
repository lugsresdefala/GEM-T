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
