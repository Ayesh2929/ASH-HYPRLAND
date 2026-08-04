# 🌍 GitHub Environments Configuration

> Apply these settings manually in **GitHub → Settings → Environments**.

## Environments

### `development`
- **Deployment branch**: `develop`
- **Protection rules**: None
- **Secrets**: `DEV_API_URL`, `DEV_REDIS_URL`
- **Variables**: `ASH_ENV=development`

### `staging`
- **Deployment branch**: `release/**`
- **Protection rules**:
  - ✅ Required reviewers: 1 (project maintainer)
  - ⏱️ Wait timer: 0 minutes
- **Secrets**: `STAGING_FLY_API_TOKEN`, `STAGING_API_URL`
- **Variables**: `ASH_ENV=staging`

### `production`
- **Deployment branch**: `main`
- **Protection rules**:
  - ✅ Required reviewers: 2 (project maintainers)
  - ⏱️ Wait timer: 10 minutes
  - 🔒 Prevent self-review
- **Secrets**: `FLY_API_TOKEN`, `PROD_API_URL`, `PROD_REDIS_URL`
- **Variables**: `ASH_ENV=production`

### `preview`
- **Deployment branch**: All branches (PR previews)
- **Protection rules**: None
- **Secrets**: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`

### `github-pages`
- **Deployment branch**: `main`
- **Protection rules**: None
- **Managed by**: GitHub Pages settings
