resource "aws_iam_role" "ecs_task_execution_role" {
  name = var.ecs_cluster_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_cluster" "main" {
    name = var.ecs_cluster_name
}


resource "aws_ecs_task_definition" "app" {
  family                   = "notejam-app-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "3072"
  container_definitions    = jsonencode([
    {
      name      = "notejam-app"
      image     = "${aws_ecr_repository.my_repository.repository_url}:latest"
      cpu       = 1024
      memory    = 3072
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        },
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_rds_cluster.mysql.endpoint
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = var.database_name
        }
      ]
      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = aws_secretsmanager_secret_version.rds_password_version.arn
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret_version.rds_password_version.arn
        }
      ]
    },
  ])
}
resource "aws_ecs_service" "main" {
    name            = "notejam-service"
    cluster         = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.app.arn
    desired_count   = var.app_count
    launch_type     = "FARGATE"

    network_configuration {
        security_groups  = [aws_security_group.ecs_tasks.id]
        subnets          = aws_subnet.private.*.id
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_alb_target_group.app.id
        container_name   = "notejam-app"
        container_port   = var.app_port
    }

    depends_on = [aws_ecr_repository.my_repository, aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role_policy]

}
