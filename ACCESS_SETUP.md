# Cloudflare Zero Trust Access Setup (Manual)

This guide explains how to enable centralized authentication for admin services using Cloudflare's Zero Trust Access.

## Overview

- **Protected Services** (require login): media-app-1, media-app-2, media-app-3, media-app-4, media-app-5, homarr
- **Open Services** (no login): jellyfin, media-app-6, join/media-app-7
- **Authentication**: Cloudflare Access with OAuth (Google, Microsoft, GitHub, etc.) or email-based
- **Setup Time**: ~5-10 minutes

## Architecture

```
User → https://media-app-1.example.com
  ↓
Cloudflare Zero Trust Gateway
  ↓
[Identity Check - Google/Microsoft Login]
  ↓
Allowed → Tunnel → media-app-1:8989 (local service)
```

## Step 1: Set Up Authentication Provider

1. Open [Cloudflare Zero Trust](https://one.dash.cloudflare.com)
2. Go: **Settings → Authentication**
3. Under "Login Methods", click **Add new**
4. Choose your provider:
   - **Google** (recommended) - quick setup, wide support
   - **Microsoft Azure AD** - enterprise environments
   - **GitHub** - developer-friendly
   - **One-time PIN** (Email) - no account needed (less secure)

5. For **Google**:
   - Click "Google"
   - You may be prompted to authenticate with Google
   - Cloudflare will auto-configure the connection
   - Status should show "Active"

## Step 2: Create Access Applications

For each admin service, create an Access application:

### For media-app-1:

1. Go: **Access → Applications**
2. Click **Add an application**
3. Select **Self-hosted**
4. Fill in:
   - **Application name**: `media-app-1 Admin`
   - **Session duration**: `24 hours`
   - **Application domain**: `media-app-1.example.com`

5. Click **Next**
6. Under "Add policies", click **+ Create policy**
7. Policy name: `Allow Authenticated Users`
   - **Decision**: Allow
   - **Require** → Select your OAuth provider (Google, Microsoft, etc.)
   - Click **Add rule**

8. Click **Next** and **Add application**

### Repeat for Other Admin Services:

Do the same for:
- `media-app-2.example.com`
- `media-app-3.example.com`
- `media-app-4.example.com`
- `media-app-5.example.com`
- `homarr.example.com`

### Important: Skip These (Keep Open)

Do NOT create Access applications for:
- `jellyfin.example.com` - user-facing, no auth
- `media-app-6.example.com` - user invitations, no auth
- `join.example.com` - signup portal, no auth

## Step 3: Test Access

1. Open https://media-app-1.example.com in **incognito/private mode**
2. You should be **redirected to Cloudflare login**
3. Click your OAuth provider (Google, Microsoft, etc.)
4. Authenticate with your account
5. You should be **allowed** and redirected to media-app-1
6. Click into media-app-1's settings - you should see the interface

## Step 4: Verify All Services

Test each protected service:
```
https://media-app-1.example.com  → Should require login
https://media-app-2.example.com  → Should require login
https://media-app-3.example.com  → Should require login
https://media-app-4.example.com  → Should require login
https://media-app-5.example.com  → Should require login
https://homarr.example.com       → Should require login
https://jellyfin.example.com     → Should load immediately (no login)
```

## Session Management

- **Default duration**: 24 hours
- **After timeout**: You'll be redirected to login again
- **Clear cookies**: Manually logout by clearing cookies or using incognito mode

### Change Session Duration (Optional):

1. Go: **Access → Applications**
2. Click the application name (e.g., "media-app-1 Admin")
3. Edit: **Session duration** (options: 30m, 1h, 2h, 6h, 12h, 24h, 7 days, 30 days)
4. Save changes

## Adding Additional Users

By default, **anyone** with your OAuth provider account can access protected services.

### To Restrict to Specific Users:

1. Go: **Access → Applications**
2. Click application name
3. Edit the policy
4. Change **Require** → Select **Emails**
5. Add specific email addresses
6. Save

### Example: Only Allow Your Email

1. In policy, set:
   - **Decision**: Allow
   - **Require** → **Emails**
   - Add: `your-email@gmail.com`

## Troubleshooting

### "Access Denied" Error

**Cause**: Your email/account not in allowed list
- **Fix**: Check that you're using the correct email address
- **Fix**: Admin should add your email to the access policy

### Blank/Slow Page

**Cause**: Browser cache or service not responding
- **Fix**: Hard refresh: `Ctrl+Shift+R` (or Cmd+Shift+R on Mac)
- **Fix**: Clear cookies: Open DevTools → Application → Cookies → Delete all
- **Fix**: Try incognito mode

### "Authentication Failed" or "Invalid OAuth"

**Cause**: OAuth provider not properly configured
- **Fix**: Go back to **Settings → Authentication**
- **Fix**: Verify provider shows "Active" status
- **Fix**: Try a different OAuth provider (Google → Microsoft)

### Can't Access Any Service (Even Open Ones)

**Cause**: Tunnel connection issue, not Access
- **Fix**: Check tunnel status: `docker logs cloudflared | tail -20`
- **Fix**: Verify service is running: `docker ps | grep media-app-1`
- **Fix**: Try accessing from local network first: `curl http://192.168.64.X:8989`

## Advanced: Service-Specific Rules (Optional)

You can create multiple policies per application:

**Example**: Allow admin team to access media-app-1, but only during business hours
1. Create Policy 1:
   - **Name**: Allow Admins (Business Hours)
   - **Decision**: Allow
   - **Require**: Specific email list + Time-based rule

2. Create Policy 2:
   - **Name**: Deny Everyone Else
   - **Decision**: Deny

Policies are evaluated in order (top to bottom), so order matters!

## Disable Access (Remove Authentication)

To remove authentication and make services public:

1. Go: **Access → Applications**
2. For each app, click **Delete**
3. Services will be immediately accessible without login

⚠️ **Security Warning**: After deletion, anyone on the internet can access your admin services!

## Reference: Service Purposes

| Service | Purpose | Should Auth? |
|---------|---------|--------------|
| media-app-1 | TV show manager | ✅ Yes - admin only |
| media-app-2 | Movie manager | ✅ Yes - admin only |
| media-app-3 | Indexer manager | ✅ Yes - admin only |
| media-app-4 | Usenet downloader | ✅ Yes - admin only |
| media-app-5 | Subtitle manager | ✅ Yes - admin only |
| Homarr | Dashboard/Portal | ✅ Yes - admin only |
| Jellyfin | Media player | ❌ No - user-facing |
| media-app-6 | Request manager | ❌ No - public invites |
| media-app-7 (join) | Invite portal | ❌ No - public signup |

## What's Next?

After Access is working:
- Add other users to access policies
- Set up service-specific role access (advanced)
- Monitor access logs in Cloudflare dashboard
- Consider adding MFA (Multi-Factor Authentication)

