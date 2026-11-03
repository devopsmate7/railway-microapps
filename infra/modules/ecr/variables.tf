variable "name_prefix" {
  description = "Repo name prefix, for example railway-dev gives railway-dev/frontend"
  type        = string
}

variable "repositories" {
  description = "One ECR repository per service"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "MUTABLE lets a tag be overwritten. IMMUTABLE does not"
  type        = string
  default     = "IMMUTABLE"
}

variable "force_delete" {
  description = "Allow terraform destroy to delete repos that still contain images"
  type        = bool
  default     = false
}

variable "keep_images" {
  description = "How many images to keep per repository"
  type        = number
  default     = 20
}
