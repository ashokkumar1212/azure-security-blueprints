resource "azurerm_public_ip" "pip_fw" {
  name                = "pip-fw-prod-eastus"
  location            = "East US"
  resource_group_name = "rg-architect-prod-eastus"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "hub_fw" {
  name                = "afw-prod-hub-eastus"
  location            = "East US"
  resource_group_name = "rg-architect-prod-eastus"
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_fw.id
  }
}

resource "azurerm_firewall_network_rule_collection" "allow_web_to_db" {
  name                = "fw-rule-web-to-db"
  azure_firewall_name = azurerm_firewall.hub_fw.name
  resource_group_name = "rg-architect-prod-eastus"
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "Allow-PostgreSQL-Web-to-DB"
    source_addresses      = ["10.101.1.0/24"]
    destination_addresses = ["10.102.1.0/24"]
    destination_ports     = ["5432"]
    protocols             = ["TCP"]
  }
}

resource "azurerm_route_table" "spoke_udr" {
  name                = "rt-spoke-to-hub-firewall"
  location            = "East US"
  resource_group_name = "rg-architect-prod-eastus"

  route {
    name                   = "Force-All-Traffic-To-Hub-Firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.100.1.4"
  }
}

resource "azurerm_subnet_route_table_association" "web_subnet_udr_assoc" {
  subnet_id      = azurerm_subnet.web_tier.id
  route_table_id = azurerm_route_table.spoke_udr.id
}
