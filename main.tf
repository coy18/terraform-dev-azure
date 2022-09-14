terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}
# Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
provider "azurerm" {
  features {}
}
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "test-rg2-dev-env" {
  name     = "test-rg2-dev"
  location = "East Us2"
  tags = {
    environment = "dev"
  }
}
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "test-rg2-dev-vn" {
  name                = "test-rg2-vn"
  resource_group_name = azurerm_resource_group.test-rg2-dev-env.name
  location            = azurerm_resource_group.test-rg2-dev-env.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "dev"
  }
}
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "test-rg2-dev-subnet" {
  name                 = "dev-subnetA"
  resource_group_name  = azurerm_resource_group.test-rg2-dev-env.name
  virtual_network_name = azurerm_virtual_network.test-rg2-dev-vn.name
  address_prefixes     = ["10.0.1.0/24"]
}
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "test-rg2-dev-nsg" {
  name                = "dev-nsg"
  location            = azurerm_resource_group.test-rg2-dev-env.location
  resource_group_name = azurerm_resource_group.test-rg2-dev-env.name
  tags = {
    environment = "dev"
  }

}
# network_security_rule https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule
resource "azurerm_network_security_rule" "test-rg2-dev-nsr" {
  name                   = "dev-rule"
  priority               = 100
  direction              = "Inbound"
  access                 = "Allow"
  protocol               = "*"
  source_port_range      = "*"
  destination_port_range = "*"
  # it is strongly recommended to put your public ip. right now its allowing anyone to see your ip add. for this demo will leave *
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.test-rg2-dev-env.name
  network_security_group_name = azurerm_network_security_group.test-rg2-dev-nsg.name
}
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
resource "azurerm_subnet_network_security_group_association" "test-rg2-dev-sga" {
  subnet_id                 = azurerm_subnet.test-rg2-dev-subnet.id
  network_security_group_id = azurerm_network_security_group.test-rg2-dev-nsg.id
}
# public_ip https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
# note: Public IP Addresses aren't allocated until they're assigned to a resource such as; vm, LB..
resource "azurerm_public_ip" "test-rg2-dev-pubip" {
  name                = "dev-publicIP"
  resource_group_name = azurerm_resource_group.test-rg2-dev-env.name
  location            = azurerm_resource_group.test-rg2-dev-env.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}
#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "test-rg2-dev-nic" {
  name                = "dev-nic"
  location            = azurerm_resource_group.test-rg2-dev-env.location
  resource_group_name = azurerm_resource_group.test-rg2-dev-env.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test-rg2-dev-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test-rg2-dev-pubip.id
  }
  tags = {
    environment = "dev"
  }
}
# create linux vm 
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
resource "azurerm_linux_virtual_machine" "test-rg2-dev-ubuntu" {
  name                = "dev-ubuntu18.04"
  resource_group_name = azurerm_resource_group.test-rg2-dev-env.name
  location            = azurerm_resource_group.test-rg2-dev-env.location
  size                = "Standard_D2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.test-rg2-dev-nic.id,
  ]
  # bootstrap our instance and install docker engine
  # if the custom_data is not in the dir/, you need to specify the path
  # https://www.terraform.io/language/functions/filebase64#filebase64-function
  custom_data = filebase64("customdata.tpl")
# here you need to generate ssh keys
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/test-rg2-dev-key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  # pass-on the var from windows-ssh-script.tpl
  # https://www.terraform.io/language/functions/templatefile
  # the Provisioner will be  setup within the azurerm_linux_virtual_machine block 

# hostname = self.<refer-to-terraform.tfstate-to-view-the-publicIP 
# identityfile = path to your ssh key 
# local-exec means running locally.  
# templatfile function to pass in variables  
# interpreter dictating whether we're using PS, bash or whatever shell we're using to run the script.
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      # you can refer to terraform.state>public_ip_address to view the public ip
      # "self" - https://www.terraform.io/language/resources/provisioners/syntax#the-self-object
      hostname     = self.public_ip_address,
      user         = "adminuser"
      identityfile = "~/.ssh/test-rg2-dev-key"
    })
    # here we set logic to choose what program (shell) to choose depending on the root module host_os. since Im using windows, it select Powershell as the command.
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

  tags = {
    environment = "dev"
  }
}
# (Optional)We can use Data Source to access that IP within Azure without having to dig through the state file. 
#  Data Source is NOT a resource, this is just to query our public ip instead of digging into our state file.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip
data "azurerm_public_ip" "test-rg2-dev-data" {
  name                = azurerm_public_ip.test-rg2-dev-pubip.name
  resource_group_name = azurerm_resource_group.test-rg2-dev-env.name
}
# (Optional) Outputs - utilizing outputs to display information that we need. manually querying our pubip is inefficient so add an output to make it easier.
# you can also run "terraform output"
output "linuxvm_pub_ip" {
  value = "${azurerm_linux_virtual_machine.test-rg2-dev-ubuntu.name} :${data.azurerm_public_ip.test-rg2-dev-data.ip_address}"
}

