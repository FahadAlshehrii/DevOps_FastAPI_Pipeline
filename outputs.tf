output "vm_public_ip" {
  description = "The public IP address of the Virtual Machine"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "acr_login_server" {
  description = "The URL of the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}