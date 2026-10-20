# ---------------------------------------------------------
# OUTPUTS
# Values Terraform prints after "terraform apply" (and with "terraform output").
# ./get-stage1-values.sh collects the ones that Stage 2 needs.
# ---------------------------------------------------------
# For you: the builder EC2 details.
output "builder_public_ip" {
  value = aws_instance.builder.public_ip
}

output "builder_instance_id" {
  value = aws_instance.builder.id
}

# Needed by Stage 2: the address of the database.
# Also used by initialize-database.sh (as RDS_ENDPOINT).
output "db_endpoint" {
  value = aws_db_instance.mysql.address
}

# Needed by Stage 2: the network the containers run in.
output "vpc_id" {
  value = aws_vpc.main.id
}

# Needed by Stage 2: the subnets where the containers are started.
output "public_subnet_a_id" {
  value = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public_b.id
}

# Needed by Stage 2: the load balancer address (shown at the end as the app URL).
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

# Needed by Stage 2: the firewall attached to every container.
output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

# Needed by Stage 2: the target groups the ECS services register into.
output "tg_frontend_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "tg_grafana_arn" {
  value = aws_lb_target_group.grafana.arn
}

output "tg_prometheus_arn" {
  value = aws_lb_target_group.prometheus.arn
}
