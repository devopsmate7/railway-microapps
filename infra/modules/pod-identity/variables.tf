variable "name" {
  description = "IAM role name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster that runs the pod"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the ServiceAccount"
  type        = string
}

variable "service_account" {
  description = "Kubernetes ServiceAccount the pod runs as"
  type        = string
}

variable "policy_json" {
  description = "IAM policy the pod receives"
  type        = string
}
