output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_registry" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "booking_service_role_arn" {
  value = module.booking_pod_identity.role_arn
}

output "github_actions_role_arn" {
  description = "Put this in the GitHub repo variable AWS_ROLE_ARN_DEV or AWS_ROLE_ARN_PROD"
  value       = module.github_oidc.role_arn
}
