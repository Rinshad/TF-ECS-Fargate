resource "aws_secretsmanager_secret" "rds_password" {
  name        = "${var.app_prefix}-rdsmysql-password"
  description = "MySQL admin password"
}

resource "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({
    username = var.rds_admin_username
    password = random_password.rds_password.result
  })
}

# Generate a random password for the RDS MySQL admin user
resource "random_password" "rds_password" {
  length  = 16
  special = true
}

# Create the MySQL RDS cluster
resource "aws_rds_cluster" "mysql" {
  cluster_identifier      = "${var.app_prefix}-mysql-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.11.1"
  master_username         = jsondecode(aws_secretsmanager_secret_version.rds_password_version.secret_string)["username"]
  master_password         = jsondecode(aws_secretsmanager_secret_version.rds_password_version.secret_string)["password"]
  database_name           = var.database_name
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot     = true
}

# Define the MySQL RDS instance
resource "aws_rds_cluster_instance" "mysql_instance" {
  count               = var.rds_instance_count
  identifier          = "${var.app_prefix}-mysql-instance-${count.index}"
  cluster_identifier  = aws_rds_cluster.mysql.id
  instance_class      = "db.t3.medium"
  engine              = aws_rds_cluster.mysql.engine
  engine_version      = aws_rds_cluster.mysql.engine_version
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}

# Create an RDS Subnet Group that includes the private subnets
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "notejam-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  description = "RDS subnet group for private subnets"
}

# Security group for RDS to allow only traffic from ECS subnets
resource "aws_security_group" "rds_sg" {
  name   = "${var.app_prefix}-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block  # Allow only from private subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM policy to allow ECS tasks to retrieve the secret from Secrets Manager
resource "aws_iam_policy" "ecs_rds_access_policy" {
  name = "${var.app_prefix}-ecs-rds-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.rds_password.arn
      }
    ]
  })
}

# Attach the IAM policy to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_rds_access_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_rds_access_policy.arn
}
