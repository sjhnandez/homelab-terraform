output "tunnel_tokens" {
  description = "Tunnel tokens for docker-compose environment"
  value = {
    for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnels :
    key => {
      tunnel_id = tunnel.id
      token     = data.cloudflare_zero_trust_tunnel_cloudflared_token.tokens[key].token
      cname     = "${tunnel.id}.cfargotunnel.com"
    }
  }
  sensitive = true
}

output "tunnel_info" {
  description = "Tunnel information"
  value = {
    for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.tunnels :
    key => {
      name      = tunnel.name
      tunnel_id = tunnel.id
      cname     = "${tunnel.id}.cfargotunnel.com"
    }
  }
}
