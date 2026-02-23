terraform {
  required_version = ">= 1.3.0"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "= 4.0.4"
    }
  }
}

provider "ncloud" {
  access_key  = var.ncloud_access_key
  secret_key  = var.ncloud_secret_key
  region      = "KR"
  site        = "public"
  support_vpc = true
}
