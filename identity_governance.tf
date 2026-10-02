resource "azuread_conditional_access_policy" "strict_mfa_policy" {
  display_name = "CAP-Enforce-Compliant-Device-and-Phishing-Resistant-MFA"
  state        = "enabled"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    users {
      included_users = ["All"]
      excluded_users = ["usr-breakglass-prod-eastus@yourtenant.onmicrosoft.com"]
    }

    locations {
      included_locations = ["All"]
      excluded_locations = ["AllTrustedLocations"]
    }

    platforms {
      included_platforms = ["all"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa", "compliantDevice"]
  }
}
