# Cloudflare Zero Trust Access - Automated Setup (v5.24+)
# Note: Uses v5 resource names (cloudflare_zero_trust_access_*)
# In v5, application-scoped policies are defined inline in the application resource

locals {
  # Derive Access-protected services from var.tunnels (defined in the
  # gitignored terraform.tfvars), mirroring the for_each pattern in tunnels.tf.
  # Any route marked `access = true` gets a Zero Trust Access application.
  # Map key = route hostname (matches the live for_each instance keys),
  # map value = application name (first DNS label of the hostname).
  admin_services = merge([
    for tunnel in values(var.tunnels) : {
      for route in tunnel.routes : route.hostname => split(".", route.hostname)[0]
      if route.access
    }
  ]...)
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
    for hostname, app in cloudflare_zero_trust_access_application.admin : hostname => {
      name   = app.name
      domain = app.domain
      url    = "https://${app.domain}"
    }
  } : {}
}
