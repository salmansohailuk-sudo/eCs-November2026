# ---------------------------------------------------------
# DATABASE
# A managed MySQL database (RDS). The backend and Grafana containers
# read and write their data here.
# ---------------------------------------------------------
# Tells RDS which subnets it may use (it needs subnets in two zones).
resource "aws_db_subnet_group" "mysql" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

# The database server.
#   - MySQL 8.0 is pinned because the MariaDB client on the builder EC2
#     cannot log in to the newest MySQL versions.
#   - db.t3.micro is the smallest (cheapest) size.
#   - db_name creates an empty database called "ecomm". The tables are
#     created later by initialize-database.sh.
#   - skip_final_snapshot = true means "terraform destroy" will not ask for
#     a backup. Fine for testing.
# Terraform waits until the database is available, so it is ready to use
# as soon as "terraform apply" finishes.
resource "aws_db_instance" "mysql" {
  identifier        = "${var.project_name}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = var.db_username
  password = var.db_password
  db_name  = "ecomm"

  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name

  skip_final_snapshot = true
}
