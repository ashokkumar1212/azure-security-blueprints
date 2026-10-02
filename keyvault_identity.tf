# 1. Fetch current Azure Client Tenant Context
data "azurerm_client_config" "current" {}

# 2. Deploy Azure Key Vault with Default-Deny Network ACLs & Azure RBAC
resource "azurerm_key_vault" "kv_prod" {
  name                        = "kv-architect-prod-eastus"
  location                    = "East US"
  resource_group_name         = "rg-architect-prod-eastus"
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"
  rbac_authorization_enabled  = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

# 3. User-Assigned Managed Identity for GitHub Actions CI/CD Pipeline
resource "azurerm_user_assigned_identity" "gh_actions_identity" {
  name                = "id-github-actions-prod"
  location            = "East US"
  resource_group_name = "rg-architect-prod-eastus"
}

# 4. Workload Identity Federated Credential (OIDC - Secretless Auth)
resource "azurerm_federated_identity_credential" "gh_actions_federated" {
  name                      = "fed-github-actions-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.gh_actions_identity.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:ashokkumar1212/azure-security-blueprints:ref:refs/heads/main"
}

# 5. Azure RBAC Role Assignment for Key Vault Access
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv_prod.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.gh_actions_identity.principal_id
}
