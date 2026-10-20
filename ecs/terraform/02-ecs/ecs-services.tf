# ---------------------------------------------------------
# TASK DEFINITIONS AND SERVICES
# How ECS runs our containers:
#   - A TASK DEFINITION is the recipe for a container: which image, how much
#     CPU and memory, which ports, which environment variables, where to log.
#   - A SERVICE keeps the wanted number of copies (tasks) running, restarts
#     them if they stop, plugs them into the load balancer (so users reach
#     them) and into service discovery (so other containers find them).
# We have 4 of each: frontend, backend, prometheus and grafana.
# ---------------------------------------------------------
# The full image address for each container: <repository address>:latest
# (the repository addresses come from the lookups in ecr.tf).
locals {
  frontend_image   = "${data.aws_ecr_repository.frontend.repository_url}:latest"
  backend_image    = "${data.aws_ecr_repository.backend.repository_url}:latest"
  prometheus_image = "${data.aws_ecr_repository.prometheus.repository_url}:latest"
  grafana_image    = "${data.aws_ecr_repository.grafana.repository_url}:latest"
}

# FRONTEND (Nginx web page).
#   - awsvpc: every task gets its own network interface and IP address
#   - cpu 256 / memory 512 = 0.25 vCPU / 512 MB, the smallest Fargate size
#   - BACKEND_URL tells the frontend where the backend is, using the
#     service discovery name from service-discovery.tf
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = local.frontend_image
    essential = true

    portMappings = [
      { containerPort = 80, protocol = "tcp" },
      { containerPort = 9113, protocol = "tcp" }
    ]

    environment = [
      {
        name  = "BACKEND_URL"
        value = "http://backend.${var.namespace_name}:5000"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "frontend"
      }
    }
  }])
}

# BACKEND (the API, port 5000). It needs the database and Stripe settings,
# which are passed in as environment variables.
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = local.backend_image
    essential = true

    portMappings = [
      { containerPort = 5000, protocol = "tcp" }
    ]

    environment = [
      { name = "DB_HOST", value = var.db_endpoint },
      { name = "DB_PORT", value = "3306" },
      { name = "DB_NAME", value = "ecomm" },
      { name = "DB_USER", value = var.db_username },
      { name = "DB_PASSWORD", value = var.db_password },
      { name = "STRIPE_SECRET_KEY", value = var.stripe_secret_key },
      { name = "STRIPE_WEBHOOK_SECRET", value = var.stripe_webhook_secret }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "backend"
      }
    }
  }])
}

# PROMETHEUS (collects metrics). Bigger size, and it also uses the task role
# so it can read CloudWatch.
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.project_name}-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.prometheus_task.arn

  container_definitions = jsonencode([{
    name      = "prometheus"
    image     = local.prometheus_image
    essential = true

    portMappings = [
      { containerPort = 9090, protocol = "tcp" },
      { containerPort = 9106, protocol = "tcp" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "prometheus"
      }
    }
  }])
}

# GRAFANA (dashboards). It reads metrics from Prometheus (by its
# service discovery name) and data from the database.
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.project_name}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "grafana"
    image     = local.grafana_image
    essential = true

    portMappings = [
      { containerPort = 3000, protocol = "tcp" }
    ]

    environment = [
      { name = "GF_SECURITY_ADMIN_USER", value = var.grafana_admin_user },
      { name = "GF_SECURITY_ADMIN_PASSWORD", value = var.grafana_admin_password },
      { name = "PROMETHEUS_URL", value = "http://prometheus.${var.namespace_name}:9090" },
      { name = "DB_HOST", value = var.db_endpoint },
      { name = "DB_PORT", value = "3306" },
      { name = "DB_NAME", value = "ecomm" },
      { name = "DB_USER", value = var.db_username },
      { name = "DB_PASSWORD", value = var.db_password }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "grafana"
      }
    }
  }])
}

# The services start the tasks.
# Frontend service:
#   - desired_count = 1 means keep one copy running
#   - assign_public_ip = true: our subnets have no NAT gateway, so a public
#     IP is how the container reaches the internet to pull its image
#   - load_balancer: register the container in the ALB target group, so the
#     ALB can send users to it
#   - service_registries: register the container in service discovery
resource "aws_ecs_service" "frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.public_subnet_a_id, var.public_subnet_b_id]
    assign_public_ip = true
    security_groups  = [var.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = var.tg_frontend_arn
    container_name   = "frontend"
    container_port   = 80
  }

  service_registries {
    registry_arn = aws_service_discovery_service.frontend.arn
  }

}

# Backend service. It has no load_balancer block because users never call it
# directly: only the frontend does, through its service discovery name.
resource "aws_ecs_service" "backend" {
  name            = "backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.public_subnet_a_id, var.public_subnet_b_id]
    assign_public_ip = true
    security_groups  = [var.ecs_security_group_id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }
}

# Prometheus service (reachable through the ALB on port 9090).
resource "aws_ecs_service" "prometheus" {
  name            = "prometheus"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.public_subnet_a_id, var.public_subnet_b_id]
    assign_public_ip = true
    security_groups  = [var.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = var.tg_prometheus_arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  service_registries {
    registry_arn = aws_service_discovery_service.prometheus.arn
  }

}

# Grafana service (reachable through the ALB on port 3000).
resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.public_subnet_a_id, var.public_subnet_b_id]
    assign_public_ip = true
    security_groups  = [var.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = var.tg_grafana_arn
    container_name   = "grafana"
    container_port   = 3000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.grafana.arn
  }

}
