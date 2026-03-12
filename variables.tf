variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "my-cicd-project-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  default     = "switzerlandnorth"
}

variable "acr_name" {
  description = "Globally unique name for the Azure Container Registry"
}

variable "ssh_public_key" {
  description = "The public SSH key for the virtual machine"
}