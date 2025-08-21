variable "role_name" {
  description = "IAM role name for Terraform apply"
  type        = string
}
variable "session_name" {
  description = "Session name for the assumed role"
  type        = string
}
variable "acc_id_devops_prd" {
  description = "Account ID for the DevOps account"
  type        = string
}
variable "map_tag_value" {
  description = "Value for the map tag"
  type        = string
  default     = "migPV0803AMRO"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.map_tag_value))
    error_message = "Map tag value must be alphanumeric, underscores, or hyphens."
  }
}