#!/bin/bash
#
# get-stage1-values.sh
# Prints the values that Stage 2 needs from Stage 1.
#
# Run this on the machine where you ran Stage 1 "terraform apply".
# It only prints text. Copy the printed lines into:
#   terraform/02-ecs/terraform.tfvars
#
# Run it from the ecs folder:   ./get-stage1-values.sh

# Check we are in the right place.
if [ ! -d terraform/01-infrastructure ]; then
  echo "ERROR: terraform/01-infrastructure not found."
  echo "Please run this script from the ecs folder."
  exit 1
fi

# Go into the Stage 1 folder, because that is where Terraform
# keeps the outputs.
cd terraform/01-infrastructure

# "terraform output -raw NAME" prints one output value on its own.
# We wrap each one in quotes so it can be pasted into a .tfvars file.
echo "# Copy these lines into terraform/02-ecs/terraform.tfvars"
echo

echo "vpc_id                = \"$(terraform output -raw vpc_id)\""
echo "public_subnet_a_id    = \"$(terraform output -raw public_subnet_a_id)\""
echo "public_subnet_b_id    = \"$(terraform output -raw public_subnet_b_id)\""
echo "ecs_security_group_id = \"$(terraform output -raw ecs_security_group_id)\""
echo "tg_frontend_arn       = \"$(terraform output -raw tg_frontend_arn)\""
echo "tg_grafana_arn        = \"$(terraform output -raw tg_grafana_arn)\""
echo "tg_prometheus_arn     = \"$(terraform output -raw tg_prometheus_arn)\""
echo "alb_dns_name          = \"$(terraform output -raw alb_dns_name)\""
echo "db_endpoint           = \"$(terraform output -raw db_endpoint)\""
