variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the control plane"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the control plane ENIs and the worker nodes"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "Who can reach the public Kubernetes API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
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

variable "addons" {
  description = "EKS managed add-ons. eks-pod-identity-agent is required for the booking-service role"
  type        = list(string)
  default     = ["vpc-cni", "kube-proxy", "coredns", "eks-pod-identity-agent"]
}
