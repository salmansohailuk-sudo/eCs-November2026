# ---------------------------------------------------------
# CLUSTER AND LOGS
# ---------------------------------------------------------
# An ECS cluster is a logical group that our services run in.
# With Fargate there are no servers to manage: AWS runs the containers for us.
# containerInsights turns on extra CPU and memory metrics.
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Container logs are sent here (CloudWatch Logs) and kept for 7 days.
# Use it to see why a container fails to start.
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}
