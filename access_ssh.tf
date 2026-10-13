# GitHub Actions SSH deploy endpoint (ssh.superseb.xyz).
#
# The hostname route lives in terraform.tfvars (apps tunnel ->
# ssh://host.docker.internal:22); this file manages its Zero Trust Access
# lockdown: machine-only access via a service token, no interactive identity.
# GitHub Actions presents the token as CF-Access-Client-Id /
# CF-Access-Client-Secret through `cloudflared access ssh`.
resource "cloudflare_zero_trust_access_application" "gha_ssh" {
  account_id       = var.cloudflare_account_id
  name             = "gha-deploy-ssh"
  domain           = "ssh.superseb.xyz"
  type             = "ssh"
  session_duration = "24h"

  policies = [
    {
      name       = "Service token only"
      decision   = "non_identity"
      precedence = 1
      include = [
        {
          any_valid_service_token = {}
        }
      ]
    }
  ]
}

resource "cloudflare_zero_trust_access_service_token" "gha_deploy" {
  account_id = var.cloudflare_account_id
  name       = "github-actions-deploy"
  duration   = "forever"
}

output "gha_deploy_service_token_client_id" {
  description = "Access service token client id for the GitHub Actions deploy SSH endpoint"
  value       = cloudflare_zero_trust_access_service_token.gha_deploy.client_id
  sensitive   = true
}

output "gha_deploy_service_token_client_secret" {
  description = "Access service token client secret for the GitHub Actions deploy SSH endpoint"
  value       = cloudflare_zero_trust_access_service_token.gha_deploy.client_secret
  sensitive   = true
}
