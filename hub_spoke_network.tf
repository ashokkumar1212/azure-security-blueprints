# 1. Define the Hub Virtual Network (The Transit & Security Zone)
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-prod-hub-eastus"
  location            = "East US"
  resource_group_name = "rg-architect-prod-eastus"
  address_space       = ["10.100.0.0/16"]
}

# 2. Secure Subnet for Azure Firewall (NIST PEP)
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet" # Azure mandates this exact name
  resource_group_name  = "rg-architect-prod-eastus"
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.100.1.0/24"]
}

# 3. Secure Subnet for Bastion Management
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = "rg-architect-prod-eastus"
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.100.2.0/24"]
}

# 4. Spoke 1 Virtual Network (The Isolated Workload Zone)
resource "azurerm_virtual_network" "spoke_web_vnet" {
  name                = "vnet-prod-spoke-web"
  location            = "East US"
  resource_group_name = "rg-architect-prod-eastus"
  address_space       = ["10.101.0.0/16"]
}

resource "azurerm_subnet" "web_tier" {
  name                 = "snet-web-frontend"
  resource_group_name  = "rg-architect-prod-eastus"
  virtual_network_name = azurerm_virtual_network.spoke_web_vnet.name
  address_prefixes     = ["10.101.1.0/24"]
}

# 5. Enforce Micro-Segmentation via Network Security Groups (NSGs)
resource "azurerm_network_security_group" "web_nsg" {
  name                = "nsg-web-frontend"
  location            = "East US"
  resource_group_name = "rg-architect-prod-eastus"

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "10.101.1.0/24"
  }
}