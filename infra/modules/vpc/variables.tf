variable "name" {
  description = "Name prefix for every VPC resource"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability Zones, one per subnet pair"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs, same order as azs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs, same order as azs"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "One NAT for all private subnets (cheaper) instead of one per AZ"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name, used for the subnet discovery tags"
  type        = string
}
