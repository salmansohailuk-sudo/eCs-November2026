# ---------------------------------------------------------
# SERVICE DISCOVERY (AWS Cloud Map)
# Every time a container starts it gets a new IP address, so other containers
# cannot rely on it. Service discovery gives each service a stable DNS name
# inside the VPC. For example the frontend reaches the backend at
# backend.testcluster.local, whatever the backend's current IP is.
# ---------------------------------------------------------
# The namespace is the private DNS domain (testcluster.local).
# It only works inside our VPC.
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = var.namespace_name
  description = "Private ECS service discovery namespace"
  vpc         = var.vpc_id
}

# One entry per service. When an ECS service starts a container, ECS adds its
# IP to this name (an "A" record), and removes it when the container stops.
# Creates frontend.testcluster.local
resource "aws_service_discovery_service" "frontend" {
  name = "frontend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Creates backend.testcluster.local
resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Creates prometheus.testcluster.local (Grafana reads its data from here).
resource "aws_service_discovery_service" "prometheus" {
  name = "prometheus"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Creates grafana.testcluster.local
resource "aws_service_discovery_service" "grafana" {
  name = "grafana"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
