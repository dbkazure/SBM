# a.	A single web page(HTML) hosted on an auto scaling group.(Default nodes =2). Web servers should  be in Compute Subnet. (Refer annex 1 - (1) for HTML file content.)
# b.	The web service should be behind an Load Balancer, place this load balancer in the DMZ subnet. Load balance with sticky IP algo.
# c.	A security group that allows only 1 local IP address to ssh into the vm instances.

#Provider
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "myrg" {
  name     = "myvmssrg"
  location = "East Asia"
}

# Vitural network
resource "azurerm_virtual_network" "myvnet" {
  name                = "vmssvnet"
  address_space       = ["172.33.0.0/16"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_subnet" "compute" {
  name                 = "compute"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["172.33.128.0/18"] # compute with a /18 prefix
  depends_on           = [azurerm_virtual_network.myvnet]
}

# Subnet DMZ
resource "azurerm_subnet" "dmz" {
  name                 = "dmz"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["172.33.0.0/18"] # dmz with a /18 prefix
  depends_on           = [azurerm_virtual_network.myvnet]
}

resource "azurerm_network_security_group" "myvmssnsg" {
  name                = "myvmssnsg"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_network_security_rule" "nsgrule" {
  name                        = "example-allow"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myrg.name
  network_security_group_name = azurerm_network_security_group.myvmssnsg.name
}





#VM Scale Set

resource "azurerm_linux_virtual_machine_scale_set" "myvmss" {
  name                            = "my-vmss"
  resource_group_name             = azurerm_resource_group.myrg.name
  location                        = azurerm_resource_group.myrg.location
  sku                             = "Standard_DS1_v2"
  instances                       = 2
  admin_username                  = "adminuser"
  admin_password                  = "!tempP@ss"
  disable_password_authentication = false

 

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.compute.id
    }
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
   connection {
    type     = "ssh"
    user     = "adminuser"
    password = "!tempP@ss"
    host     = azurerm_linux_virtual_machine_scale_set.myvmss.id
    
  }
}

resource "azurerm_storage_account" "scriptstore" {
  name                     = "scriptstore202310171"
  resource_group_name      = azurerm_resource_group.myrg.name
  location                 = azurerm_resource_group.myrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "scriptfile" {
  name                  = "scriptfile"
  storage_account_name  = "scriptstore202310171"
  container_access_type = "blob"
  depends_on=[
    azurerm_storage_account.scriptstore
    ]
}

# Uploading script to blob

resource "azurerm_storage_blob" "script" {
  name                   = "script.sh"
  storage_account_name   = "scriptstore202310171"
  storage_container_name = "scriptfile"
  type                   = "Block"
  source                 = "script.sh"
   depends_on=[azurerm_storage_container.scriptfile]
}

// Here we are applying the custom script extension on the 
// virtual machine scale set
resource "azurerm_virtual_machine_scale_set_extension" "scaleset_extension" {
  name                 = "scaleset-extension"
  virtual_machine_scale_set_id   = azurerm_linux_virtual_machine_scale_set.myvmss.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  depends_on = [
    azurerm_storage_blob.script
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.scriptstore.name}.blob.core.windows.net/scriptfile/script.sh"],
          "commandToExecute": "/bin/bash script.sh"     
    }
SETTINGS
}


