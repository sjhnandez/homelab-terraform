# Create Cloudflare Zero Trust tunnels (remotely managed via config_src="cloudflare")
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnels" {
  for_each = var.tunnels

  account_id = var.cloudflare_account_id
  name       = each.value.name
  # config_src = "cloudflare" is the default for remotely-managed tunnels
  # secret is NOT provided - tunnel is configured via cloudflare_zero_trust_tunnel_cloudflared_config
}

# Get tunnel token for use in `cloudflared tunnel run --token`
data "cloudflare_zero_trust_tunnel_cloudflared_token" "tokens" {
  for_each = var.tunnels

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels[each.key].id
}

# Configure tunnel ingress routes (hosted on Cloudflare)
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "configs" {
  for_each = var.tunnels

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels[each.key].id

  config = {
    ingress = concat(
      [
        for route in each.value.routes : merge(
          {
            hostname = route.hostname
            service  = route.service
          },
          route.path != null ? { path = route.path } : {},
          route.origin_request != null ? { origin_request = route.origin_request } : {}
        )
      ],
      [{
        service = "http_status:404"
      }]
    )
  }
}

# Create DNS CNAME records pointing to tunnel CNAME
resource "cloudflare_dns_record" "tunnel_cnames" {
  for_each = merge([
    for tunnel_key, tunnel in var.tunnels : {
      for route in tunnel.routes :
      "${tunnel_key}-${route.hostname}" => {
        hostname  = route.hostname
        tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tunnels[tunnel_key].id
      }
    }
  ]...)

  zone_id = var.cloudflare_zone_id
  name    = each.value.hostname
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.tunnels[split("-", each.key)[0]].id}.cfargotunnel.com"
  ttl     = 1 # Automatic TTL
  proxied = true
  comment = "Managed by Terraform"
}
