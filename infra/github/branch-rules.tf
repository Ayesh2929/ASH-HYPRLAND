terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "Ayesh2929"
}

# ── Main Branch Protection ──────────────────────────────────

resource "github_branch_protection" "main" {
  repository_id = "ASH-HYPRLAND"
  pattern       = "main"

  enforce_admins          = true
  required_signed_commits = true
  allows_force_pushes     = false
  allows_deletions        = false

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    require_last_push_approval      = true
  }

  required_status_checks {
    strict   = true
    contexts = [
      "✅ Linting",
      "🧪 Test",
      "🔒 Security",
      "📜 Compliance"
    ]
  }
}

# ── Develop Branch Protection ───────────────────────────────

resource "github_branch_protection" "develop" {
  repository_id = "ASH-HYPRLAND"
  pattern       = "develop"

  enforce_admins      = false
  allows_force_pushes = true
  allows_deletions    = false

  required_status_checks {
    strict   = false
    contexts = [
      "✅ Linting",
      "🧪 Test"
    ]
  }
}

# ── Release Branch Protection ──────────────────────────────

resource "github_branch_protection" "release" {
  repository_id = "ASH-HYPRLAND"
  pattern       = "release/*"

  enforce_admins      = true
  allows_force_pushes = false
  allows_deletions    = false

  required_pull_request_reviews {
    required_approving_review_count = 2
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
  }

  required_status_checks {
    strict   = true
    contexts = [
      "✅ Linting",
      "🧪 Test",
      "🔒 Security",
      "📜 Compliance",
      "🏗️ Build",
      "🎭 E2E Tests"
    ]
  }
}
