# ---------------------------------------------------------
# PERMISSIONS FOR THE BUILDER EC2
# An IAM role gives the server permission to use AWS, so we never type
# access keys on it.
# ---------------------------------------------------------
# The role. The assume_role_policy says "EC2 servers may use this role".
resource "aws_iam_role" "builder" {
  name = "${var.project_name}-builder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# An instance profile is the wrapper that attaches a role to an EC2 server.
resource "aws_iam_instance_profile" "builder" {
  name = "${var.project_name}-builder-profile"
  role = aws_iam_role.builder.name
}

# The builder EC2 runs Terraform for Stage 2 (ECS, IAM roles, Cloud Map, logs).
# AdministratorAccess keeps the test setup simple - tighten for anything real.
resource "aws_iam_role_policy_attachment" "builder_admin" {
  role       = aws_iam_role.builder.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
