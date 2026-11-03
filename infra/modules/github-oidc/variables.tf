variable "role_name" {
  description = "IAM role that GitHub Actions assumes"
  type        = string
}

variable "github_repo" {
  description = "owner/repo allowed to assume the role"
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if another environment in this account already made it"
  type        = bool
  default     = true
}

variable "ecr_repository_arns" {
  description = "ECR repositories this role can push to and pull from"
  type        = list(string)
}
