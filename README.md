# Cloudflare Tunnels - Terraform Configuration

This Terraform configuration manages Cloudflare Zero Trust tunnels (cloudflared) for the network stack.

## Overview

- **Pattern**: Remotely-managed tunnels (config hosted on Cloudflare, not local)
- **Provider**: Cloudflare Terraform Provider v5.24+
- **DNS**: Automatic CNAME records pointing to tunnel endpoint
- **Tunnels**: Managed entirely via Terraform

## Prerequisites

1. **Cloudflare Account**: https://dash.cloudflare.com/
2. **Terraform**: v1.5+ (install: `sudo apt-get install terraform`)
3. **Account/Zone IDs**: Get from Cloudflare dashboard
4. **API Token**: Create with proper permissions

## Quick Start

### 1. Create API Token

Go to https://dash.cloudflare.com/profile/api-tokens and click "Create Token"

**Custom token setup:**
- Select "Custom token"
- Set permissions:
  - Account → Cloudflare Tunnel: Edit
  - Zone → DNS: Edit
- Create and copy the token

### 2. Configure terraform.tfvars

```hcl
cloudflare_api_token = "cfut_xxx..."
cloudflare_account_id = "your-account-id"
cloudflare_zone_id    = "your-zone-id"

tunnels = {
  homelab = {
    name = "homelab-tunnel"
    domain = "example.com"
    routes = [
      {
        hostname = "jellyfin.example.com"
        service  = "http://jellyfin:8096"
      },
      {
        hostname = "media-app-2.example.com"
        service  = "http://media-app-2:7878"
      }
    ]
  }
}
```

### 3. Initialize & Deploy

```bash
cd terraform
terraform init
terraform plan          # Review changes
terraform apply         # Apply configuration
```

### 4. Get Tunnel Tokens

After `terraform apply`, extract tunnel tokens:

```bash
# View all tunnel info
terraform output tunnel_info

# Extract specific tunnel token
terraform output -json tunnel_tokens | jq '.homelab.token' -r
```

### 5. Run cloudflared Container

```bash
export CLOUDFLARED_TOKEN=$(terraform output -json tunnel_tokens | jq '.homelab.token' -r)
docker run -d --name cloudflared \
  -e CLOUDFLARED_TOKEN=$CLOUDFLARED_TOKEN \
  cloudflare/cloudflared:latest \
  tunnel run --token $CLOUDFLARED_TOKEN
```

Or use docker-compose (see [docker-compose.example.yml](docker-compose.example.yml))

## Managing Tunnels

### Add a Route

Edit `terraform.tfvars`, add to `tunnels.homelab.routes`:

```hcl
{
  hostname = "plex.example.com"
  service  = "http://plex:32400"
}
```

Apply:
```bash
terraform apply
```

### Remove a Tunnel

Delete from `tunnels` in `terraform.tfvars`, then `terraform apply`

### Rotate Tunnel Token

```bash
terraform taint 'cloudflare_zero_trust_tunnel_cloudflared.tunnels[homelab]'
terraform apply
```

## Common Commands

```bash
# Review planned changes
terraform plan

# Apply configuration
terraform apply

# View tunnel information
terraform output tunnel_info

# Get tunnel tokens
terraform output -json tunnel_tokens

# List all resources
terraform state list

# Validate configuration
terraform validate
```

## Troubleshooting

### Tunnel not connecting
1. Verify token: `terraform output tunnel_tokens`
2. Check container: `docker logs cloudflared`
3. Verify DNS: Check Cloudflare dashboard → DNS records

### Syntax errors
```bash
terraform validate
terraform fmt .
```

### State issues
```bash
terraform refresh
```

## Security

- ✅ `.gitignore` protects credentials and state
- ✅ Never commit `terraform.tfvars`
- ✅ Never commit `terraform.tfstate*`
- ✅ Rotate API tokens periodically
- ✅ Use remote backend (Terraform Cloud/S3) in production

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Provider configuration |
| `variables.tf` | Input variables |
| `tunnels.tf` | Tunnel and DNS resources |
| `outputs.tf` | Outputs (tunnel tokens and info) |
| `terraform.tfvars` | Configuration (credentials, tunnels) |
| `.gitignore` | Protects secrets and state |

## Documentation

- [Cloudflare Terraform Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Terraform Docs](https://www.terraform.io/docs)
