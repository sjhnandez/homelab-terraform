# Cloudflare Tunnels - Quick Reference

## Setup (3 Steps)

```bash
# 1. Create API token at https://dash.cloudflare.com/profile/api-tokens
#    Permissions: Account > Cloudflare Tunnel:Edit, Zone > DNS:Edit

# 2. Edit terraform.tfvars with:
#    - cloudflare_api_token = "your-token"
#    - cloudflare_account_id
#    - cloudflare_zone_id
#    - tunnels configuration

# 3. Deploy
cd homelab-terraform
terraform init
terraform apply
```

## Extract Tunnel Tokens

```bash
# View all tunnels and tokens
terraform output tunnel_info
terraform output tunnel_tokens

# Extract single token for docker-compose
export CLOUDFLARED_TOKEN=$(terraform output -json tunnel_tokens | jq '.TUNNEL_NAME.token' -r)
```

## Common Commands

```bash
# Plan changes
terraform plan

# Apply configuration
terraform apply

# List resources
terraform state list

# Validate syntax
terraform validate

# Format code
terraform fmt .
```

## Add/Modify Tunnels

1. Edit `terraform.tfvars` - modify `tunnels` variable
2. Run `terraform plan` to preview
3. Run `terraform apply`

## Remove a Tunnel

1. Delete from `tunnels` in `terraform.tfvars`
2. Run `terraform apply`

## Rotate Tunnel Token

```bash
terraform taint 'cloudflare_zero_trust_tunnel_cloudflared.tunnels[TUNNEL_NAME]'
terraform apply
```

## Troubleshooting

```bash
# Refresh state from Cloudflare
terraform refresh

# Check configuration
terraform validate

# View all outputs
terraform output

# Format issues
terraform fmt -check .

# Debug provider
TF_LOG=DEBUG terraform apply
```

## Security Checklist

- [ ] Token not in git (`.gitignore` protects it)
- [ ] State not in git (`.gitignore` protects it)
- [ ] `terraform.tfvars` not in git
- [ ] API token stored securely
- [ ] Use remote backend in production
