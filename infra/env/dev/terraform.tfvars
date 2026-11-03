environment = "dev"
region      = "ap-south-1"

# Network: one NAT gateway to keep the bill low
vpc_cidr           = "10.10.0.0/16"
azs                = ["ap-south-1a", "ap-south-1b"]
public_subnets     = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnets    = ["10.10.10.0/24", "10.10.11.0/24"]
single_nat_gateway = true

# EKS: Spot nodes for training, 1 node to start (cheapest). Bump node_desired_size
# to 2 later if you want to practice rolling updates across nodes.
cluster_version     = "1.33"
node_instance_types = ["t3.medium", "t3a.medium"]
node_capacity_type  = "SPOT"
node_min_size       = 1
node_max_size       = 2
node_desired_size   = 1

# ECR: tags can be overwritten, repos can be destroyed with images inside
ecr_image_tag_mutability = "MUTABLE"
ecr_force_delete         = true

# DynamoDB: no backups or delete lock in dev
dynamodb_point_in_time_recovery = false
dynamodb_deletion_protection    = false

# GitHub Actions: dev is applied first, so it creates the account's OIDC provider
github_repo                 = "devopsmate7/railway-microapps"
create_github_oidc_provider = true
