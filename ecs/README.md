# ECS October 2026 (learning project)

Two Terraform stages, and three scripts you run yourself:

| Step | What | Where |
|---|---|---|
| Stage 1 | `terraform/01-infrastructure`: network, database, load balancer, builder EC2 | your laptop |
| `get-stage1-values.sh` | prints the values Stage 2 needs | your laptop |
| `initialize-database.sh` | creates the database tables | builder EC2 |
| `build-images.sh` | builds the images, creates ECR repositories, uploads the images | builder EC2 |
| Stage 2 | `terraform/02-ecs`: ECS cluster, tasks and services | builder EC2 |

Nothing is left waiting: the images are already in ECR when Stage 2 starts the containers.

---

## The steps

### 1. Stage 1 - infrastructure + load balancer (your laptop)

Push this repo to GitHub first (the builder EC2 downloads it from there), then:

```bash
cd ecs/terraform/01-infrastructure
terraform init
terraform apply
```

### 2. Get the Stage 1 values (your laptop)

```bash
cd ecs
./get-stage1-values.sh
```

It prints 9 lines. Keep them, you paste them in step 4. They are explained below.

### 3. Connect to the builder EC2

AWS Console -> EC2 -> builder -> Connect -> EC2 Instance Connect (user `ec2-user`).
Wait until this file exists:

```bash
ls ~/ecs-october-2026/READY
```

### 4. Save the Stage 1 values (builder EC2)

```bash
cd ~/ecs-october-2026/ecs/terraform/02-ecs
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars      # paste the 9 lines, then set the Stripe keys and Grafana password
```

### 5. Create the database tables (builder EC2)

Use the `db_endpoint` value from step 2:

```bash
cd ~/ecs-october-2026/ecs
export RDS_ENDPOINT="paste db_endpoint here"
export DB_PASSWORD="Cloud123"
./initialize-database.sh
```

### 6. Build the images and upload them to ECR (builder EC2)

```bash
./build-images.sh
```

It does three things: builds the 4 images, creates the 4 ECR repositories if they
do not exist yet, and uploads the images. You can run it again at any time: existing
repositories are kept and the new images replace the old ones.

### 7. Stage 2 - ECS (builder EC2)

```bash
cd ~/ecs-october-2026/ecs/terraform/02-ecs
terraform init
terraform apply
```

When it finishes it prints the URLs (also shown by `terraform output`). The containers
need a few minutes to start and pass the load balancer health checks:

- App: `http://<alb>`
- Grafana: `http://<alb>:3000`
- Prometheus: `http://<alb>:9090`

---

## What Stage 1 builds

| File | What it builds |
|---|---|
| `vpc.tf` | The network: a VPC, two public subnets (two zones), internet gateway, route table |
| `security-groups.tf` | Firewalls for the builder EC2, the database and the ECS containers |
| `rds.tf` | A MySQL 8.0 database (RDS) with an empty database called `ecomm` |
| `alb.tf` | The load balancer, its firewall, 3 target groups and 3 listeners (ports 80, 3000, 9090) |
| `iam.tf` | The permission (role) for the builder EC2 |
| `builder-ec2.tf` | The builder EC2, which installs Docker, Git, MariaDB client and Terraform on first boot |
| `outputs.tf` | The values printed after apply |

## The values Stage 1 passes to Stage 2

| Value | What it is | Why Stage 2 needs it |
|---|---|---|
| `vpc_id` | The network | Service discovery (private DNS) is created inside it |
| `public_subnet_a_id`, `public_subnet_b_id` | The two subnets | Where ECS starts the containers |
| `ecs_security_group_id` | Firewall for containers | Attached to every container |
| `tg_frontend_arn`, `tg_grafana_arn`, `tg_prometheus_arn` | Load balancer target groups | Each ECS service registers its containers here, so the load balancer can send users to them |
| `alb_dns_name` | The load balancer address | Used to print the URLs |
| `db_endpoint` | The database address | Given to the backend and Grafana containers |

You also give Stage 2 your own values: the database password, the Stripe keys and the Grafana password.

## What Stage 2 builds, and how ECS works

| File | What it builds |
|---|---|
| `ecr.tf` | Nothing: it looks up the 4 ECR repositories made by `build-images.sh` |
| `ecs-cluster.tf` | The ECS cluster (a group to run services in) and a log group for container logs |
| `iam.tf` | The ECS execution role (pull images, write logs) and Prometheus's task role (read CloudWatch) |
| `service-discovery.tf` | A private DNS domain (`testcluster.local`) and a name for each service |
| `ecs-services.tf` | 4 task definitions and 4 services |

How it fits together:

1. A **task definition** is the recipe for a container: image, CPU, memory, ports, environment variables.
2. A **service** keeps the wanted number of tasks running and restarts them if they stop.
3. With **Fargate**, AWS runs the containers: there are no servers to manage.
4. The service registers each container in the load balancer **target group** (users reach it) and in
   **service discovery** (other containers reach it, for example the frontend calls `backend.testcluster.local`).
5. ECS pulls the image from ECR, which is why `build-images.sh` runs first.

---

## Starting again in a new AWS account

1. Run `aws configure` and enter the new account's keys.
2. From the `ecs` folder run `./reset-stage1.sh`. It shows the account number, deletes the old
   Terraform state and lock files, and runs `terraform init`.
3. Push your latest files to GitHub (the builder downloads them from there).
4. Follow the steps above again, starting at step 1.

## Destroy

1. Builder EC2: `terraform destroy` in `terraform/02-ecs`
2. Builder EC2: delete the ECR repositories (Terraform did not create them, so it does not remove them):
   ```bash
   aws ecr delete-repository --repository-name ecomm-ecs-frontend --force
   aws ecr delete-repository --repository-name ecomm-ecs-backend --force
   aws ecr delete-repository --repository-name monitoring-ecs-prometheus --force
   aws ecr delete-repository --repository-name monitoring-ecs-grafana --force
   ```
3. Your laptop: `terraform destroy` in `terraform/01-infrastructure`

## Notes

- Testing only: Fargate in public subnets, open load balancer ports, builder EC2 has AdministratorAccess.
- The state of Stage 2 lives on the builder EC2, so destroy Stage 2 before Stage 1.
- Never commit `terraform.tfvars`.
