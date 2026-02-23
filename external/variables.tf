variable "ncloud_access_key" {
  description = "NCP access key"
  type        = string
  sensitive   = true
}

variable "ncloud_secret_key" {
  description = "NCP secret key"
  type        = string
  sensitive   = true
}

variable "coss_vpc_no" {
  description = "Existing COSS VPC number"
  type        = string
  default     = "133450"
}

variable "coss_vpc_cidr" {
  description = "Existing COSS VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "coss-ext"
}

variable "zone" {
  description = "NCP zone"
  type        = string
  default     = "KR-1"
}

variable "coss_api_base_url" {
  description = "COSS API base URL (optional)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "Operator public IP CIDR allowed to access external bastion SSH"
  type        = string
}

variable "server_image_product_code" {
  description = "Optional server image product code override"
  type        = string
  default     = null
}

variable "server_product_code" {
  description = "Optional server product code override"
  type        = string
  default     = null
}

variable "alb_ssl_certificate_no" {
  description = "NCP Certificate Manager certificate number for ALB HTTPS listener"
  type        = string
  default     = "57361"
}

variable "bootstrap_public_key" {
  description = "SSH public key injected into bootstrap user_data scripts"
  type        = string
}