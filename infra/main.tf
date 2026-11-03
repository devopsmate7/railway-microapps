locals {
  name = "${var.project}-${var.environment}"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "./modules/vpc"

  name               = local.name
  cidr               = var.vpc_cidr
  azs                = var.azs
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  single_nat_gateway = var.single_nat_gateway
  cluster_name       = local.name
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = local.name
  cluster_version     = var.cluster_version
  subnet_ids          = module.vpc.private_subnet_ids
  public_access_cidrs = var.eks_public_access_cidrs
  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix          = local.name
  repositories         = var.services
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.ecr_force_delete
}

module "dynamodb" {
  source = "./modules/dynamodb"

  table_name             = "${local.name}-bookings"
  point_in_time_recovery = var.dynamodb_point_in_time_recovery
  deletion_protection    = var.dynamodb_deletion_protection
}

data "aws_iam_policy_document" "booking_dynamodb" {
  statement {
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      module.dynamodb.table_arn,
      "${module.dynamodb.table_arn}/index/*",
    ]
  }
}

module "booking_pod_identity" {
  source = "./modules/pod-identity"

  name            = "${local.name}-booking-service"
  cluster_name    = module.eks.cluster_name
  namespace       = var.app_namespace
  service_account = "booking-service"
  policy_json     = data.aws_iam_policy_document.booking_dynamodb.json
}

module "github_oidc" {
  source = "./modules/github-oidc"

  role_name            = "${local.name}-github-actions"
  github_repo          = var.github_repo
  create_oidc_provider = var.create_github_oidc_provider
  ecr_repository_arns  = module.ecr.repository_arns
}
