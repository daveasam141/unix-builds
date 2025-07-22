terraform {
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "2.14.0"
    }
  }
}
# provider.tf
provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  
  # Allow unverified SSL certificates
  allow_unverified_ssl = true
}