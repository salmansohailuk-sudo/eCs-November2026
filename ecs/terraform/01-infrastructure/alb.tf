# ---------------------------------------------------------
# LOAD BALANCER
# The ALB (Application Load Balancer) is the single public entry point.
# Users open the ALB address, and the ALB forwards each request to a healthy
# container. We build it here in Stage 1, so it already exists when Stage 2
# starts the containers.
# ---------------------------------------------------------
# Firewall for the load balancer: the internet may reach ports 80 (app),
# 3000 (Grafana) and 9090 (Prometheus). Open to everyone, testing only.
resource "aws_security_group" "alb" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Application HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana HTTP for testing"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus HTTP for testing"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The load balancer itself. internal = false means it is reachable from the
# internet. It sits in both public subnets.
resource "aws_lb" "main" {
  name               = substr("${var.project_name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# A target group is the list of places the ALB sends traffic to.
# Starts empty: in Stage 2 each ECS service registers its containers here.
#   - target_type = "ip": Fargate containers have their own IP address
#   - health_check: the ALB calls this path every 30 seconds and only sends
#     traffic to containers that answer correctly.
# Stage 2 receives the ARN (the unique ID) of each target group.
resource "aws_lb_target_group" "frontend" {
  name        = substr("${var.project_name}-frontend", 0, 32)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Target group for Grafana (port 3000).
resource "aws_lb_target_group" "grafana" {
  name        = substr("${var.project_name}-grafana", 0, 32)
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/api/health"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Target group for Prometheus (port 9090).
resource "aws_lb_target_group" "prometheus" {
  name        = substr("${var.project_name}-prometheus", 0, 32)
  port        = 9090
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/-/ready"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# A listener waits for traffic on a port and says what to do with it.
# Port 80 -> forward to the frontend target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Port 3000 -> forward to the Grafana target group.
resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.main.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

# Port 9090 -> forward to the Prometheus target group.
resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = aws_lb.main.arn
  port              = 9090
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }
}
