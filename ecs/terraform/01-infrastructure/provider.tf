# ---------------------------------------------------------
# Tells Terraform to use the AWS provider (the plugin that talks to AWS)
# and which region to create everything in.
# ---------------------------------------------------------
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
