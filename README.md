# railway-microapps

A train ticket booking app split into three microservices, used to teach Docker, EKS, Argo CD, and GitHub Actions.

| Service | What it does | Port |
|---|---|---|
| `frontend` | Booking page (name, from, to, date). nginx serves it and forwards `/api` calls | 8080 |
| `train-service` | Station list and the trains between two stations | 8000 |
| `booking-service` | Saves the ticket to DynamoDB and returns a PNR. Calls `train-service` to check the train | 8000 |

```
browser ??? frontend (nginx) ??? /api/trains    ??? train-service
                              ??? /api/bookings ??? booking-service ??? DynamoDB
                                                          ??? train-service
```

## Folder layout

```
services/                 three apps, one Dockerfile each
docker-compose.yml        run everything on a laptop with DynamoDB Local
deploy/k8s/base/          Deployments and Services, shared by every env
deploy/k8s/overlays/dev   dev table name, 1 replica, dev ECR images
deploy/k8s/overlays/prod  prod table name, 2 replicas, prod ECR images
deploy/argocd/            Argo CD Application per environment
.github/workflows/        ci-dev (build and deploy dev) and promote-prod
infra/                    Terraform root
infra/modules/            vpc, eks, ecr, dynamodb, pod-identity, github-oidc
infra/env/dev|prod/       terraform.tfvars and backend.hcl per environment
```

## 1. Docker on the laptop

```bash
docker compose up --build
```

Open http://localhost:8080, book a ticket, and it appears under Recent bookings. Data lives in DynamoDB Local and is gone when the container stops.

## 2. Terraform: build dev on AWS

Create the state bucket once, then put its name in both `env/*/backend.hcl` files.

```bash
aws s3 mb s3://railway-tfstate-<your-account-id> --region ap-south-1
aws s3api put-bucket-versioning --bucket railway-tfstate-<your-account-id> --versioning-configuration Status=Enabled
```

```bash
cd infra
terraform init -backend-config=env/dev/backend.hcl
terraform plan  -var-file=env/dev/terraform.tfvars
terraform apply -var-file=env/dev/terraform.tfvars
```

This creates the VPC, the EKS cluster, three ECR repos, the `railway-dev-bookings` table, the IAM role booking-service uses through Pod Identity, and the GitHub Actions role.

For prod, switch the state and the vars file. Apply dev first, because dev creates the GitHub OIDC provider that prod reuses.

```bash
terraform init -reconfigure -backend-config=env/prod/backend.hcl
terraform apply -var-file=env/prod/terraform.tfvars
```

## 3. GitHub Actions

In the GitHub repo, open **Settings ? Secrets and variables ? Actions ? Variables** and add:

| Variable | Value |
|---|---|
| `AWS_ACCOUNT_ID` | your 12-digit account id |
| `AWS_ROLE_ARN_DEV` | `github_actions_role_arn` output from dev |
| `AWS_ROLE_ARN_PROD` | `github_actions_role_arn` output from prod |

- **ci-dev** runs on every push to `main` that touches `services/`. It builds all three images, pushes them to `railway-dev/*` tagged with the commit SHA, and commits the new tag into `deploy/k8s/overlays/dev`.
- **promote-prod** is started by hand with a commit SHA. It copies those exact images into `railway-prod/*` and commits the tag into the prod overlay.

Run **ci-dev** once (Actions ? ci-dev ? Run workflow) before step 4, so the dev overlay points at real images.

## 4. EKS and Argo CD

```bash
aws eks update-kubeconfig --region ap-south-1 --name railway-dev
kubectl get nodes

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f deploy/argocd/railway-dev.yaml
```

Argo CD UI:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

Open https://localhost:8443 and log in as `admin`.

The app URL:

```bash
kubectl -n railway get svc frontend
```

Open `http://<EXTERNAL-IP>` and book a ticket. The item shows up in the `railway-dev-bookings` DynamoDB table.

On the prod cluster, apply `deploy/argocd/railway-prod.yaml` instead. Prod has no auto-sync, so press **Sync** in the UI after a promotion.

## The full loop

1. Change something in `services/`, push to `main`.
2. ci-dev builds and pushes the images, then commits the new tag to the dev overlay.
3. Argo CD sees that commit and rolls dev forward.
4. Test dev, then run promote-prod with that commit SHA.
5. Press Sync on prod in Argo CD.

## Tear down

```bash
kubectl -n railway delete svc frontend   # removes the AWS load balancer first
cd infra
terraform destroy -var-file=env/dev/terraform.tfvars
```

Prod has DynamoDB deletion protection on. Set `dynamodb_deletion_protection = false` and apply before destroying it.
