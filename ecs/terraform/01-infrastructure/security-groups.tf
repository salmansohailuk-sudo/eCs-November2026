# ---------------------------------------------------------
# FIREWALLS
# A security group is a firewall that controls what traffic may reach a resource.
# (The load balancer's security group is in alb.tf.)
# ---------------------------------------------------------
# Builder EC2: allow SSH (port 22) so we can connect with EC2 Instance Connect.
# All outgoing traffic is allowed (needed to download packages and Docker images).
resource "aws_security_group" "builder" {
  name   = "${var.project_name}-builder-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "EC2 Instance Connect / SSH for testing"
    from_port   = 22
    to_port     = 22
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

# Database: MySQL (port 3306) is allowed only from inside our VPC, which means
# from the builder EC2 and from the ECS containers, but not from the internet.
resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = aws_vpc.main.id

  # Testing setup: allow MySQL from this VPC so both the builder EC2
  # and ECS Fargate tasks can initialise/use the database.
  ingress {
    description = "MySQL from project VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS containers (created in Stage 2). Traffic may come in:
#   - from the load balancer, on the three application ports
#   - from inside the VPC, so containers can talk to each other
#     (for example frontend -> backend)
# We create it here because the load balancer's security group is also here.
# Stage 2 receives its ID as ecs_security_group_id.
resource "aws_security_group" "ecs" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Frontend from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Grafana from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Prometheus from ALB"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Internal traffic between services"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
