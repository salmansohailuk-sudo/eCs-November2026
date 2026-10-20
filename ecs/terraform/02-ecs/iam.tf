# ---------------------------------------------------------
# PERMISSIONS FOR ECS
# ECS uses two different kinds of role.
# ---------------------------------------------------------
# EXECUTION role: used by ECS itself, not by our application.
# It lets ECS pull the images from ECR and write the logs.
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# AWS provides this ready-made policy for that job.
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# TASK role: used by the application running inside the container.
# Only Prometheus needs one, to read metrics from CloudWatch.
resource "aws_iam_role" "prometheus_task" {
  name = "${var.project_name}-prometheus-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# What the Prometheus task is allowed to do: read CloudWatch metrics.
resource "aws_iam_role_policy" "prometheus_cloudwatch" {
  name = "${var.project_name}-prometheus-cloudwatch"
  role = aws_iam_role.prometheus_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "tag:GetResources"
      ]
      Resource = "*"
    }]
  })
}
