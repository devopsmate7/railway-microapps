variable "project" {
  description = "Prefix for every resource name"
  type        = string
  default     = "railway"
}

variable "environment" {
  description = "dev or prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

# ?? Network ??
variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

# ?? EKS ??
variable "cluster_version" {
  type = string
}

variable "eks_public_access_cidrs" {
  description = "Who can reach the Kubernetes API from the internet"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_desired_size" {
  type = number
}

variable "app_namespace" {
  description = "Kubernetes namespace the app runs in"
  type        = string
  default     = "railway"
}

# ?? ECR ??
variable "services" {
  description = "One ECR repository per microservice"
  type        = list(string)
  default     = ["frontend", "train-service", "booking-service"]
}

variable "ecr_image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"
}

variable "ecr_force_delete" {
  type    = bool
  default = false
}

# ?? DynamoDB ??
variable "dynamodb_point_in_time_recovery" {
  type    = bool
  default = false
}

variable "dynamodb_deletion_protection" {
  type    = bool
  default = false
}

# ?? GitHub Actions ??
variable "github_repo" {
  description = "owner/repo that is allowed to push images"
  type        = string
}

variable "create_github_oidc_provider" {
  description = "true for the first environment in this AWS account, false for the next"
  type        = bool
  default     = true
}
