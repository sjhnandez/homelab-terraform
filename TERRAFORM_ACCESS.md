# Cloudflare Access Automation - Two Approaches

## TL;DR

**Yes, Terraform can automate Access creation**, but requires a provider version change.

- ✅ **Current state**: access.tf is ready for v4.20+ provider
- ⚙️ **Your current provider**: v5.24 (doesn't have Access resources)
- 🔄 **To enable**: Change provider to v4.20+ and provide identity_provider_id

---

## Approach 1: Full Terraform Automation (Recommended)

### Prerequisites

1. **Update Terraform Provider Version**

   Edit [main.tf](main.tf):
   ```hcl
   version = "~> 4.20"  # Change from "~> 5.24"
   ```

   This downgrade is **safe** - v4.20 still supports all tunnel functionality plus Access.

2. **Set Identity Provider ID**

   Edit [terraform.tfvars](terraform.tfvars):
   ```hcl
   cloudflare_identity_provider_id = "google-oauth2"  # Or your provider ID
   ```

   How to get your ID:
   - Go: https://one.dash.cloudflare.com/access/settings/authentication
   - Click **Add new** and enable a provider (Google, Microsoft, GitHub, etc.)
   - The ID will appear (e.g., `google-oauth2` or `507f1f77bcf86cd799439011`)
   - Copy it to terraform.tfvars

3. **Apply Terraform**

   ```bash
   cd /home/server/stacks/network/terraform
   terraform init     # Downloads provider v4.20
   terraform plan     # Shows Access applications to be created
   terraform apply    # Creates 6 Access applications + policies
   ```

4. **What Gets Created**

   - 6 Access Applications (one per admin service)
   - 1 Policy per application (allow authenticated users)
   - Automatically configured for your OAuth provider
   - All services protected with 24-hour session duration

### Verification

After applying:

```bash
# See created applications:
terraform output access_applications

# Test access:
# https://media-app-1.example.com → Redirects to login
# https://jellyfin.example.com → Loads immediately (not protected)
```

### Advantages

✅ Infrastructure-as-Code (reproducible, version controlled)
✅ Fully automated (no manual steps in Cloudflare UI)
✅ Easy to modify (adjust session duration, add users, etc.)
✅ Portable (can redeploy everything with one command)
✅ Audit trail (git history shows all changes)

---

## Approach 2: Manual Setup (Current State)

If you prefer **not** to change the provider version:

1. Don't update main.tf (keep v5.24)
2. Leave `cloudflare_identity_provider_id = ""` in terraform.tfvars
3. Follow [ACCESS_SETUP.md](ACCESS_SETUP.md) for manual Cloudflare UI steps
4. Takes ~5-10 minutes, no Terraform changes needed

### Advantages

✅ No provider version change required
✅ Simpler if you prefer UI-based setup
✅ Good for one-time configuration

### Disadvantages

❌ Not infrastructure-as-code
❌ Manual steps to repeat if needed
❌ Harder to track changes
❌ Not portable to other systems

---

## Recommendation

**Use Approach 1** (provider v4.20 + Terraform automation) because:

1. **v4.20 is stable** - it's an older but well-tested version
2. **Your tunnels continue working** - tunnel resources are compatible
3. **Full automation** - git tracks all your security configuration
4. **Future flexibility** - easy to add users, change policies, etc.
5. **Only 3 steps**: Update provider → Set identity ID → Apply

---

## Migration Path

If you're currently on v5.24 with other resources:

```bash
# 1. Update main.tf version to v4.20
# 2. Run terraform plan (should show no changes if only using tunnels)
# 3. Add access.tf resources (already created)
# 4. Run terraform apply (creates Access policies)
```

**Safe**: Downgrading to v4.20 won't affect your tunnel configuration - they're compatible.

---

## Troubleshooting

### "terraform validate" fails with Access resources

**Cause**: Provider is still v5.24
**Fix**: 
```bash
cd /home/server/stacks/network/terraform
rm .terraform.lock.hcl     # Force provider update
terraform init             # Downloads v4.20
terraform validate         # Should pass now
```

### "identity_provider_id is empty"

**Cause**: You haven't set it in terraform.tfvars
**Fix**:
1. Go: https://one.dash.cloudflare.com/access/settings/authentication
2. Add a provider (click "Add new")
3. Copy the ID
4. Update terraform.tfvars
5. Run `terraform apply`

### Access applications show "No policy configured"

**Cause**: Policy wasn't created
**Fix**:
1. Check terraform output: `terraform output access_applications`
2. Run `terraform plan` to see what should exist
3. Run `terraform apply` to sync

---

## Next Steps

Choose your approach:

**Option A: Full Terraform (Recommended)**
1. Edit main.tf: Change version to "~> 4.20"
2. Edit terraform.tfvars: Add your identity_provider_id
3. Run: `terraform apply`
4. Done! Access applications created automatically

**Option B: Manual Setup**
1. Keep terraform.tfvars with empty identity_provider_id
2. Follow ACCESS_SETUP.md for manual steps
3. No Terraform changes needed

---

## Files Involved

- **[main.tf](main.tf)** - Update provider version here (Approach 1)
- **[access.tf](access.tf)** - Access resource definitions (ready to use)
- **[variables.tf](variables.tf)** - identity_provider_id variable defined
- **[terraform.tfvars](terraform.tfvars)** - Set your identity_provider_id here
- **[ACCESS_SETUP.md](ACCESS_SETUP.md)** - Manual setup guide (Approach 2)
