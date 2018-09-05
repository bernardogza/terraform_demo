variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "tenant_id" {
  description = "The Azure tenant ID"
}

variable "client_id" {
  description = "The Azure client ID"
}
variable "secret_access_key" {
  description = "The Azure secret access key" 
}

variable "public_key" {
  description = "Public Key" 
}

# Configure the Azure Provider
provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.secret_access_key}"
  tenant_id = "${var.tenant_id}"
}

terraform {
  required_version = ">= 0.11.7"
}

#Create resource Group
resource "azurerm_resource_group" "Terraform_Demo_RG" {
  name= "Terraform_Demo"
  location = "North Central US"
}

#Create virtual network
resource "azurerm_virtual_network" "Terraform_Demo_VN" {
  name = "Terraform_Demo_VN"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  address_space = ["10.0.0.0/16"]
  location = "North Central US"
  
}

#Create Subnet
resource "azurerm_subnet" "Terraform_Demo_SN"{
  name ="Terraform-Demo-SN"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  virtual_network_name = "${azurerm_virtual_network.Terraform_Demo_VN.name}"
  address_prefix = "10.0.2.0/24"
}

#Create Public IP address
resource "azurerm_public_ip" "Terraform_Demo_IP" {
  name = "TerraformDemoPublicIP"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_public_ip" "Terraform_Demo_IP_2" {
  name = "TerraformDemoPublicIP_2"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  public_ip_address_allocation = "static"
}


resource "azurerm_public_ip" "Terraform_Demo_IP_3" {
  name = "TerraformDemoPublicIP_3"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  public_ip_address_allocation = "static"
}

#Create Network Scurity Gorup
resource "azurerm_network_security_group" "Terraform_Demo_NSG" {
  name = "Terraform_Demo_NSG"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"

  security_rule {
    name = "security"
    priority = 101
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

#Create virtual network interface card
resource "azurerm_network_interface" "Terraform_Demo_NI" {
  name = "Terraform_Demo_NI"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  network_security_group_id = "${azurerm_network_security_group.Terraform_Demo_NSG.id}"

  ip_configuration {
    name = "Terraform-Demo-IPCONFIG"
    subnet_id = "${azurerm_subnet.Terraform_Demo_SN.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.Terraform_Demo_IP.id}"
  }
}

resource "azurerm_network_interface" "Terraform_Demo_NI_2" {
  name = "Terraform_Demo_NI_2"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  network_security_group_id = "${azurerm_network_security_group.Terraform_Demo_NSG.id}"

  ip_configuration {
    name = "Terraform-Demo-IPCONFIG2"
    subnet_id = "${azurerm_subnet.Terraform_Demo_SN.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.Terraform_Demo_IP_2.id}"
  }
}

resource "azurerm_network_interface" "Terraform_Demo_NI_3" {
  name = "Terraform_Demo_NI_3"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  network_security_group_id = "${azurerm_network_security_group.Terraform_Demo_NSG.id}"

  ip_configuration {
    name = "Terraform-Demo-IPCONFIG3"
    subnet_id = "${azurerm_subnet.Terraform_Demo_SN.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.Terraform_Demo_IP_3.id}"
  }
}

#Create storage account
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.Terraform_Demo_RG.name}"
    }
    byte_length = 8
}

resource "azurerm_storage_account" "Terraform_Demo_SA" {
  name = "diag${random_id.randomId.hex}"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  location = "North Central US"
  account_replication_type = "LRS"
  account_tier = "Standard"
}

#Create virtual machine
resource "azurerm_virtual_machine" "Terraform_Server" {
  name = "Consul-Server-VM"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  network_interface_ids = ["${azurerm_network_interface.Terraform_Demo_NI.id}"]
  vm_size = "Standard_DS1_v2"

  storage_os_disk {
        name              = "TerrafomDemoOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "Demo"
        admin_username = "bernardogza"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/bernardogza/.ssh/authorized_keys"
            key_data = "${var.public_key}"
    }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.Terraform_Demo_SA.primary_blob_endpoint}"
    }
    
    connection {
      user = "bernardogza"
      //private_key = "/home/bernardogza/.ssh/"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get install -y curl unzip",
        "sudo mkdir -p /var/lib/consul",
        "sudo mkdir -p /usr/share/consul",
        "sudo mkdir -p /etc/consul/conf.d",
        "sudo curl -OL https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip",
        "sudo unzip consul_1.2.2_linux_amd64.zip",
        "sudo mv consul /usr/local/bin/consul",
        "cd /etc/consul/conf.d",
        "sudo touch config.json"
        ]
    }
}

resource "azurerm_virtual_machine" "Terraform_Server_2" {
  name = "Consul-Server-2"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  network_interface_ids = ["${azurerm_network_interface.Terraform_Demo_NI_2.id}"]
  vm_size = "Standard_DS1_v2"

  storage_os_disk {
        name              = "TerrafomDemoOsDisk2"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "Demo"
        admin_username = "bernardogza"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/bernardogza/.ssh/authorized_keys"
            key_data = "${var.public_key}"
    }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.Terraform_Demo_SA.primary_blob_endpoint}"
    }
    
    connection {
      user = "bernardogza"
      //private_key = "/home/bernardogza/.ssh/"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get install -y curl unzip",
        "sudo mkdir -p /var/lib/consul",
        "sudo mkdir -p /usr/share/consul",
        "sudo mkdir -p /etc/consul/conf.d",
        "sudo curl -OL https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip",
        "sudo unzip consul_1.2.2_linux_amd64.zip",
        "sudo mv consul /usr/local/bin/consul",
        "cd /etc/consul/conf.d",
        "sudo touch config.json"
        ]
    }
}

resource "azurerm_virtual_machine" "Terraform_Client" {
  name = "Consul-Client"
  location = "North Central US"
  resource_group_name = "${azurerm_resource_group.Terraform_Demo_RG.name}"
  network_interface_ids = ["${azurerm_network_interface.Terraform_Demo_NI_3.id}"]
  vm_size = "Standard_DS1_v2"

  storage_os_disk {
        name              = "TerrafomDemoOsDisk3"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "Demo"
        admin_username = "bernardogza"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/bernardogza/.ssh/authorized_keys"
            key_data = "${var.public_key}"
    }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.Terraform_Demo_SA.primary_blob_endpoint}"
    }
    
    connection {
      user = "bernardogza"
      //private_key = "/home/bernardogza/.ssh/"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get install -y curl unzip",
        "sudo mkdir -p /var/lib/consul",
        "sudo mkdir -p /usr/share/consul",
        "sudo mkdir -p /etc/consul/conf.d",
        "sudo curl -OL https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip",
        "sudo unzip consul_1.2.2_linux_amd64.zip",
        "sudo mv consul /usr/local/bin/consul",
        "cd /etc/consul/conf.d",
        "sudo touch config.json"
        ]
    }
}

 output "public_ip_address_Server_1" {
      value = "${azurerm_public_ip.Terraform_Demo_IP.ip_address}"
 }


 output "public_ip_address_Server_2" {
      value = "${azurerm_public_ip.Terraform_Demo_IP_2.ip_address}"
 }
 

 output "public_ip_address_Client" {
      value = "${azurerm_public_ip.Terraform_Demo_IP_3.ip_address}"
 }

output "private_ip_address_Server_1" {
      value = "${azurerm_network_interface.Terraform_Demo_NI.private_ip_address}"
 }
 
 output "private_ip_address_Server_2" {
      value = "${azurerm_network_interface.Terraform_Demo_NI_2.private_ip_address}"
 }
 
 output "private_ip_address_Client" {
      value = "${azurerm_network_interface.Terraform_Demo_NI_3.private_ip_address}"
 }
 