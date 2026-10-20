# ---------------------------------------------------------
# Settings for Stage 1. Each one has a default, so you can run
# "terraform apply" without typing anything.
# ---------------------------------------------------------
# The AWS region where everything is created.
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# Used as a prefix in the names of most resources.
variable "project_name" {
  type    = string
  default = "ecs-october-2026"
}

# Master user name of the MySQL database.
variable "db_username" {
  type    = string
  default = "admin"
}

# Master password of the MySQL database (testing value).
# Stage 2 needs the same password, so you also put it in terraform.tfvars there.
variable "db_password" {
  type      = string
  sensitive = true
  default   = "Cloud123"
}
