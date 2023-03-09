terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.57.1"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}
# Define the ECS task definition
resource "aws_ecs_task_definition" "example" {
  family                   = "example-task"
  container_definitions    = jsonencode([
    {
      name            = "wordpress-container"
      image           = "ccseyhan/wordpress"
      portMappings    = [
        {
          containerPort = 80
          hostPort      = 80
        },
      ]
      essential       = true
    },
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
}
# Define the ECS service that will run the task
resource "aws_ecs_service" "example" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private.*.id
    security_groups  = [aws_security_group.example.id]
    assign_public_ip = false
  }
}

# Define any required resources, such as the VPC and subnets:
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

locals {
  azs = ["us-east-1a","us-east-1b","us-east-1c"]
}

resource "aws_subnet" "private" {
  count = 3
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = aws_vpc.example.id
  availability_zone = element(local.azs, count.index)
}

resource "aws_security_group" "example" {
  name_prefix = "example-sg"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "example" {
  name = "example-cluster"
}


# module "ecs-fargate" {
#   source  = "cn-terraform/ecs-fargate/aws"
#   version = "2.0.51"
#   vpc_id = 
#   public_subnets_ids =
#   private_subnets_ids =
#   name_prefix =
#   container_name  = "wordpress"
#   container_image = "ccseyhan/wordpress"
# }