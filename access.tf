# Cloudflare Zero Trust Access - Automated Setup (v5.24+)
# Note: Uses v5 resource names (cloudflare_zero_trust_access_*)
# In v5, application-scoped policies are defined inline in the application resource

locals {
  admin_services = {
    "media-app-1.example.com" = "media-app-1"
    "media-app-2.example.com" = "media-app-2"
    "media-app-3.example.com" = "media-app-3"
    "media-app-4.example.com" = "media-app-4"
    "media-app-5.example.com" = "media-app-5"
    "homarr.example.com"      = "homarr"
  }
}

# Create Zero Trust Access Application for each admin service
resource "cloudflare_zero_trust_access_application" "admin" {
  for_each = var.cloudflare_identity_provider_id != "" ? local.admin_services : {}

  account_id                = var.cloudflare_account_id
  name                      = each.value
  domain                    = each.key
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = true

  # Specify which identity providers are allowed
  allowed_idps = [var.cloudflare_identity_provider_id]

  policies = [
    {
      name       = "Allow Cloudflare Account Members"
      decision   = "allow"
      precedence = 1
      include = [
        {
          login_method = {
            id = var.cloudflare_identity_provider_id
          }
        }
      ]
    }
  ]
}

# Output: Access application information
output "access_applications" {
  description = "Created Zero Trust Access Applications"
  value = var.cloudflare_identity_provider_id != "" ? {
    for name, app in cloudflare_zero_trust_access_application.admin : name => {
      name   = app.name
      domain = app.domain
      url    = "https://${app.domain}"
    }
  } : {}
}
