# ---------------------------------------------------------
# IMAGE REPOSITORIES
# ---------------------------------------------------------
# build-images.sh creates the 4 ECR repositories and uploads the Docker
# images to them. Terraform does not create them. Here we only LOOK THEM UP
# by name, so we can use their addresses in the task definitions.
#
# If a repository does not exist yet, terraform stops here with an error:
# that means build-images.sh has not been run yet.

data "aws_ecr_repository" "frontend" {
  name = "ecomm-ecs-frontend"
}

data "aws_ecr_repository" "backend" {
  name = "ecomm-ecs-backend"
}

data "aws_ecr_repository" "prometheus" {
  name = "monitoring-ecs-prometheus"
}

data "aws_ecr_repository" "grafana" {
  name = "monitoring-ecs-grafana"
}
