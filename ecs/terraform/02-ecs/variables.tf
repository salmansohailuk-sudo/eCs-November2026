# ---------------------------------------------------------
# Settings for Stage 2. The values go in terraform.tfvars
# (see terraform.tfvars.example).
# ---------------------------------------------------------
# The AWS region (must be the same as in Stage 1).
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# Prefix for resource names (same as in Stage 1).
variable "project_name" {
  type    = string
  default = "ecs-october-2026"
}

# The private DNS domain for service discovery, for example backend.testcluster.local
variable "namespace_name" {
  type    = string
  default = "testcluster.local"
}

# These nine values come from Stage 1.
# You get them by running ./get-stage1-values.sh yourself.
variable "vpc_id" { type = string }  # the network (used by service discovery)
variable "public_subnet_a_id" { type = string }  # subnet where containers start
variable "public_subnet_b_id" { type = string }  # second subnet, other zone
variable "ecs_security_group_id" { type = string }  # firewall for the containers
variable "tg_frontend_arn" { type = string }  # ALB target group for the frontend
variable "tg_grafana_arn" { type = string }  # ALB target group for Grafana
variable "tg_prometheus_arn" { type = string }  # ALB target group for Prometheus
variable "alb_dns_name" { type = string }  # load balancer address, for the output URLs
variable "db_endpoint" { type = string }  # database address, given to the containers

# These are your own values.
variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "stripe_secret_key" {
  type      = string
  sensitive = true
}

variable "stripe_webhook_secret" {
  type      = string
  sensitive = true
}

variable "grafana_admin_user" {
  type    = string
  default = "admin"
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}
