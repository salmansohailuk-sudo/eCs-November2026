#!/bin/bash
#
# reset-stage1.sh
# Use this when you start again in a NEW AWS account.
# It clears the old Terraform state so Stage 1 starts fresh.
#
# Steps:
#   1. Run "aws configure" and enter the new account's keys.
#   2. Run this script from the ecs folder:   ./reset-stage1.sh
#   3. Then run "terraform apply" in terraform/01-infrastructure.

# Stop the script if any command fails.
set -e

# Check we are in the right place.
if [ ! -d terraform/01-infrastructure ]; then
  echo "ERROR: terraform/01-infrastructure not found."
  echo "Please run this script from the ecs folder."
  exit 1
fi

cd terraform/01-infrastructure

# Show which AWS account the keys belong to.
# If the keys are wrong or expired, this fails and the script stops.
echo "AWS account in use:"
aws sts get-caller-identity --query Account --output text

# Delete the old state files. They describe the OLD account's resources,
# which no longer exist.
echo "Deleting old Terraform state files..."
rm -f terraform.tfstate terraform.tfstate.backup

# Delete the old lock file(s). Terraform makes a new one in "init".
echo "Deleting old lock files..."
find . -type f -name ".terraform.lock.hcl" -delete

# Download the Terraform providers again.
echo "Running terraform init..."
terraform init

echo
echo "Reset done. Now run: terraform apply"
