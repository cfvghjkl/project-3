terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}
 
provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id 
  features {}
}
 
resource "azurerm_resource_group" "resourcegroup1" {
  name     = "resource_group"
  location = "East US"
}
 
resource "azurerm_virtual_network""virtualnetwork1" {
  name                = "virtual_network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resourcegroup1.location
  resource_group_name = azurerm_resource_group.resourcegroup1.name
}
 
resource "azurerm_subnet" "subnet" {
  name                 = "Subnet"
  resource_group_name  = azurerm_resource_group.resourcegroup1.name
  virtual_network_name = azurerm_virtual_network.virtualnetwork1.name
  address_prefixes     = ["10.0.0.0/24"]
}
 
resource "azurerm_public_ip" "public_ip" {
  name                = "Public_IP"
  resource_group_name = azurerm_resource_group.resourcegroup1.name
  location            = azurerm_resource_group.resourcegroup1.location
  allocation_method   = "Static"
}
 
resource "azurerm_network_interface" "networkinterface1" {
  name                = "mynetworkinterface"
  location            = azurerm_resource_group.resourcegroup1.location
  resource_group_name = azurerm_resource_group.resourcegroup1.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}
 
resource "azurerm_linux_virtual_machine" "linuxVM" {
  name                            = "LinuxVM"
  resource_group_name             = azurerm_resource_group.resourcegroup1.name
  location                        = azurerm_resource_group.resourcegroup1.location
  size                            = "Standard_D2_V2"
  admin_username                  = "sagarika"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.networkinterface1.id,
  ]
 
  admin_ssh_key {
    username   = "sagarika"
    public_key = file("/var/lib/jenkins/id_rsa.pub")
  }
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
 
resource "null_resource" "run_ansible_playbook" {
  depends_on = [azurerm_linux_virtual_machine.linuxVM]
 
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${azurerm_public_ip.public_ip.ip_address},' install_nginx.yml --extra-vars='ansible_ssh_user=sagarika' --private-key='/var/lib/jenkins/id_rsa' --become --become-user=root"
  }
}
