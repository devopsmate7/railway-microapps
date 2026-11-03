variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "point_in_time_recovery" {
  description = "Continuous backups for restore to any second in the last 35 days"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Block table deletion until this is turned off"
  type        = bool
  default     = false
}
