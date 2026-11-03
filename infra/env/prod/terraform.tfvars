environment = "prod"
region      = "ap-south-1"

# Network: one NAT gateway per AZ, so one AZ failing does not cut the other off
vpc_cidr           = "10.20.0.0/16"
azs                = ["ap-south-1a", "ap-south-1b"]
public_subnets     = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnets    = ["10.20.10.0/24", "10.20.11.0/24"]
single_nat_gateway = false

# EKS: On-Demand nodes, at least two
cluster_version     = "1.33"
node_instance_types = ["t3.medium"]
node_capacity_type  = "ON_DEMAND"
node_min_size       = 2
node_max_size       = 4
node_desired_size   = 2

# ECR: a promoted tag can never be overwritten
ecr_image_tag_mutability = "IMMUTABLE"
ecr_force_delete         = false

# DynamoDB: backups on, and the table cannot be deleted by accident
dynamodb_point_in_time_recovery = true
dynamodb_deletion_protection    = true

# GitHub Actions: dev already created the OIDC provider in this account
github_repo                 = "devopsmate7/railway-microapps"
create_github_oidc_provider = false
