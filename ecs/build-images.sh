#!/bin/bash
#
# build-images.sh
# Does everything needed to get the Docker images into AWS:
#   1. Builds the 4 images (frontend, backend, prometheus, grafana)
#   2. Creates the 4 ECR repositories, but only if they do not exist yet
#   3. Pushes (uploads) the new images to ECR
#
# ECR (Elastic Container Registry) is AWS's storage for Docker images.
# ECS pulls the images from there when it starts the containers.
#
# You can run this script again and again. If the repositories already
# exist, it just uploads the newly built images over the old ones.
#
# Run it from the "ecs" folder:   ./build-images.sh

# Stop the script straight away if any command fails.
set -e

# The AWS region where everything is created.
AWS_REGION=us-east-1

# ---------------------------------------------------------
# Step 0: check we are in the right folder
# ---------------------------------------------------------
# docker-compose.yml tells Docker how to build each image.
# If it is not in this folder, we are in the wrong place.
if [ ! -f docker-compose.yml ]; then
  echo "ERROR: docker-compose.yml not found."
  echo "Please run this script from the ecs folder."
  exit 1
fi

# ---------------------------------------------------------
# Step 1: build the images
# ---------------------------------------------------------
echo "Step 1: building images..."
docker compose build

# Show the images we just built (their names contain "ecs").
echo
docker images | grep ecs

# ---------------------------------------------------------
# Step 2: create the ECR repositories (only if missing)
# ---------------------------------------------------------
# "describe-repositories" succeeds if the repository exists and fails if not.
# So: if it exists we do nothing, otherwise we create it.
echo
echo "Step 2: checking the ECR repositories..."

if aws ecr describe-repositories --repository-names ecomm-ecs-frontend --region $AWS_REGION > /dev/null 2>&1; then
  echo "  ecomm-ecs-frontend already exists"
else
  aws ecr create-repository --repository-name ecomm-ecs-frontend --region $AWS_REGION > /dev/null
  echo "  ecomm-ecs-frontend created"
fi

if aws ecr describe-repositories --repository-names ecomm-ecs-backend --region $AWS_REGION > /dev/null 2>&1; then
  echo "  ecomm-ecs-backend already exists"
else
  aws ecr create-repository --repository-name ecomm-ecs-backend --region $AWS_REGION > /dev/null
  echo "  ecomm-ecs-backend created"
fi

if aws ecr describe-repositories --repository-names monitoring-ecs-prometheus --region $AWS_REGION > /dev/null 2>&1; then
  echo "  monitoring-ecs-prometheus already exists"
else
  aws ecr create-repository --repository-name monitoring-ecs-prometheus --region $AWS_REGION > /dev/null
  echo "  monitoring-ecs-prometheus created"
fi

if aws ecr describe-repositories --repository-names monitoring-ecs-grafana --region $AWS_REGION > /dev/null 2>&1; then
  echo "  monitoring-ecs-grafana already exists"
else
  aws ecr create-repository --repository-name monitoring-ecs-grafana --region $AWS_REGION > /dev/null
  echo "  monitoring-ecs-grafana created"
fi

# ---------------------------------------------------------
# Step 3: push the images to ECR
# ---------------------------------------------------------
echo
echo "Step 3: pushing images to ECR..."

# Ask AWS for our account number. It is part of the ECR address.
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# The ECR address looks like:  123456789012.dkr.ecr.us-east-1.amazonaws.com
REGISTRY=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
echo "  AWS account: $AWS_ACCOUNT_ID"
echo "  Registry:    $REGISTRY"

# Log Docker in to ECR. The login password comes from AWS and is
# passed straight into "docker login" (so it is never shown on screen).
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY

# For each image we do two things:
#   docker tag  - gives the local image its ECR name
#   docker push - uploads it to ECR

echo "  pushing frontend..."
docker tag ecomm-ecs-frontend:latest $REGISTRY/ecomm-ecs-frontend:latest
docker push $REGISTRY/ecomm-ecs-frontend:latest

echo "  pushing backend..."
docker tag ecomm-ecs-backend:latest $REGISTRY/ecomm-ecs-backend:latest
docker push $REGISTRY/ecomm-ecs-backend:latest

echo "  pushing prometheus..."
docker tag monitoring-ecs-prometheus:latest $REGISTRY/monitoring-ecs-prometheus:latest
docker push $REGISTRY/monitoring-ecs-prometheus:latest

echo "  pushing grafana..."
docker tag monitoring-ecs-grafana:latest $REGISTRY/monitoring-ecs-grafana:latest
docker push $REGISTRY/monitoring-ecs-grafana:latest

echo
echo "Done. The 4 images are in ECR."
echo "Next: run terraform apply in terraform/02-ecs"
