variable "cidr_block" {}
variable "ecs_cluster_role" {}
variable "ecs_cluster_name" {}

variable "app_prefix" {
    description = "Used to represent application"
}

variable "aws_region" {
    description = "The AWS region things are created in"
    default = "eu-central-1"
}

variable "ec2_task_execution_role_name" {
    description = "ECS task execution role name"
    default = "notejamEcsTaskExecutionRole"
}

variable "az_count" {
    description = "Number of AZs to cover in a given region"
    default = "2"
}

variable "app_image" {
    description = "Docker image to run in the ECS cluster"
    default = "711387138803.dkr.ecr.eu-central-1.amazonaws.com/notejam:latest"
}

variable "app_port" {
    description = "Port exposed by the docker image to redirect traffic to"
    default = 3000
}

variable "app_count" {
    description = "Number of docker containers to run"
    default = 1
}

variable "health_check_path" {
  default = "/signin"
}

variable "fargate_cpu" {
    description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
    default = "1024"
}

variable "fargate_memory" {
    description = "Fargate instance memory to provision (in MiB)"
    default = "2048"
}
variable "repository_name" {
   description = "ECR name"
   default = "notejam" 
}

######## RDS variables #####

variable "rds_admin_username" {
  description = "The username for the RDS MySQL admin"
  default     = "mysqladmin"
}

variable "database_name" {
  description = "The name of the database to create in the RDS cluster"
  default     = "notejam_db"
}

variable "rds_instance_count" {
  description = "The number of RDS instances in the cluster"
  default     = 1
}
