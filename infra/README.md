# 🏗️ Infrastructure as Code

This directory contains infrastructure definitions for the ASH Dotfiles project.

## Structure

```
infra/
├── README.md           # This file
├── github/
│   ├── branch-rules.tf # Branch protection rules
│   ├── labels.tf       # Repository labels (planned)
│   └── environments.tf # GitHub Environments (planned)
└── fly/
    └── fly.toml        # Fly.io application config (in api/)
```

## GitHub Infrastructure

Managed via the `integrations/github` Terraform provider.

### Prerequisites

```bash
# Install Terraform
brew install terraform  # macOS

# Set GitHub token
export GITHUB_TOKEN="ghp_your_token_here"

# Initialize and apply
cd infra/github
terraform init
terraform plan
terraform apply
```

### What's Managed

- **Branch protection rules** for `main`, `develop`, `release/*`
- Required status checks, review approvals, signed commits enforcement
- Force push and deletion policies

## Fly.io

API deployments are managed by Fly.io. Configuration lives in `api/fly.toml`.

```bash
# Deploy API
cd api
flyctl deploy --remote-only
```

## Notes

- Branch protection rules are also documented in `.github/branch-protection.json`
- Environment configurations are documented in `.github/environments.md`
- OIDC authentication is preferred over long-lived secrets where possible
