# Cloudflare Zero Trust Access - Automated Setup (Terraform)

This guide explains how to protect admin services with Cloudflare Zero Trust Access using Terraform. The Access resources live in [access.tf](access.tf) and use the Cloudflare provider v5.24+ (`cloudflare_zero_trust_access_*` resources).

> **Prefer the dashboard?** See [ACCESS_SETUP.md](ACCESS_SETUP.md) for the manual walkthrough instead. Both approaches produce the same result.

## Overview

- **Protected Services** (require login): media-app-1, media-app-2, media-app-3, media-app-4, media-app-5, homarr
- **Open Services** (no login): jellyfin, media-app-6, join/media-app-7
- **Authentication**: Cloudflare Access with an OAuth identity provider (Google, Microsoft, GitHub, etc.)
- **Session duration**: 24 hours
- **Setup time**: ~5 minutes once an identity provider exists

## What access.tf Creates

When `cloudflare_identity_provider_id` is set, Terraform creates **one Access application per route marked `access = true` in `terraform.tfvars`**:

| Application | Domain | Policy |
|-------------|--------|--------|
| media-app-1 | `media-app-1.example.com` | Allow Cloudflare Account Members |
| media-app-2 | `media-app-2.example.com` | Allow Cloudflare Account Members |
| media-app-3 | `media-app-3.example.com` | Allow Cloudflare Account Members |
| media-app-4 | `media-app-4.example.com` | Allow Cloudflare Account Members |
| media-app-5 | `media-app-5.example.com` | Allow Cloudflare Account Members |
| homarr | `homarr.example.com` | Allow Cloudflare Account Members |

Each application is configured as:

- **Type**: self-hosted
- **Session duration**: 24 hours
- **Auto redirect**: enabled - visitors go straight to your identity provider's login instead of the Access launcher
- **Policy**: an inline `allow` policy that includes anyone who authenticates through your identity provider (`login_method`)

> **v5 note**: With provider v5, the policy is defined inline inside the `cloudflare_zero_trust_access_application` resource. There is no separate policy resource to manage.

The protected services are derived in [access.tf](access.tf) from the `tunnels` variable: every route marked `access = true` in your gitignored `terraform.tfvars` becomes an Access application (see [terraform.tfvars.example](terraform.tfvars.example) for the format). Add or remove the marker on a route to change what Access protects.

## Enabling Automated Access

If `cloudflare_identity_provider_id` is left empty (the default), no Access resources are created - your tunnels and DNS still apply normally.

### Step 1: Create an Identity Provider

1. Open [Cloudflare Zero Trust](https://one.dash.cloudflare.com)
2. Go: **Settings → Authentication**
3. Under "Login Methods", click **Add new**
4. Choose a provider (Google, Microsoft Azure AD, GitHub, or One-time PIN)
5. Once active, copy the **identity provider ID** (e.g. `google-oauth2` or a numeric ID like `507f1f77bcf86cd799439011`)

### Step 2: Set the Identity Provider ID

Edit your `terraform.tfvars`:

```hcl
cloudflare_identity_provider_id = "google-oauth2"  # Or your provider ID
```

### Step 3: Apply

```bash
cd homelab-terraform
terraform init     # Installs the pinned Cloudflare provider
terraform plan     # Should show one Access application per route marked access = true
terraform apply    # Creates the Access applications and their policies
```

The provider version is pinned in [main.tf](main.tf) and recorded in the committed `.terraform.lock.hcl`, so `terraform init` always installs the same provider build.

### Step 4: Verify

```bash
# See created applications:
terraform output access_applications

# Test access:
# https://media-app-1.example.com → Redirects to login
# https://jellyfin.example.com → Loads immediately (not protected)
```

## Session Management

- **Default duration**: 24 hours (set via `session_duration` in [access.tf](access.tf))
- **After timeout**: You'll be redirected to login again

To change the duration, edit `session_duration` in [access.tf](access.tf) and run `terraform apply`.

## Removing or Disabling Access

- **Not using Access yet?** Leave `cloudflare_identity_provider_id = ""` - no Access resources are created.
- **Turn it off later**: Set `cloudflare_identity_provider_id = ""` and run `terraform apply`.
- **Protect fewer services**: Remove the `access = true` marker from the route in `terraform.tfvars` and apply.

⚠️ **Security Warning**: After disabling Access, anyone who can reach those hostnames can access the admin services!

## Troubleshooting

### No Access applications are created

**Cause**: `cloudflare_identity_provider_id` is empty in terraform.tfvars
**Fix**:
1. Create an identity provider at **Settings → Authentication** in the Zero Trust dashboard
2. Copy its ID into `cloudflare_identity_provider_id`
3. Run `terraform apply`

### Login page fails or shows "Access Denied"

**Cause**: The identity provider ID doesn't match an active provider, or you're not signed in with an allowed account
**Fix**:
1. Verify the provider shows "Active" at **Settings → Authentication**
2. Copy the exact ID and update terraform.tfvars
3. Sign in with an account from that provider

### "terraform validate" fails

**Cause**: Provider plugins are not installed
**Fix**:
```bash
cd homelab-terraform
terraform init      # Installs the pinned Cloudflare provider
terraform validate  # Should pass now
```

### `terraform output access_applications` is empty

**Cause**: Access resources haven't been applied (identity provider ID still empty)
**Fix**:
1. Set `cloudflare_identity_provider_id` and run `terraform apply`
2. Run `terraform output access_applications` again

## Files Involved

- **[main.tf](main.tf)** - Provider configuration (cloudflare v5.24+)
- **[access.tf](access.tf)** - Access applications and inline policies
- **[variables.tf](variables.tf)** - `cloudflare_identity_provider_id` variable defined
- **[terraform.tfvars](terraform.tfvars)** - Set your identity_provider_id and `access = true` route markers here
- **[ACCESS_SETUP.md](ACCESS_SETUP.md)** - Manual setup guide (alternative to Terraform)
