# ── Project ───────────────────────────────────────────────────────────────────

resource "tfe_project" "project" {
  organization = var.organization
  name         = var.project_name
}

# ── Project manager team ───────────────────────────────────────────────────

resource "tfe_team" "project_manager" {
  name         = "${var.project_name} IAC Management Team"
  organization = var.organization
}

# Ephemeral: token generated at apply time, never written to state.
ephemeral "tfe_team_token" "project_manager" {
  team_id    = tfe_team.project_manager.id
  expired_at = local.token_expiration
}

resource "tfe_team_project_access" "project_manager" {
  team_id    = tfe_team.project_manager.id
  project_id = tfe_project.project.id
  access     = "maintain"
}

# ── Workspace ─────────────────────────────────────────────────────────────────

resource "tfe_workspace" "project_manager" {
  name         = "${tfe_project.project.name} - Project Manager"
  description  = "Management workspace for project '${tfe_project.project.name}', used to manage workspaces, variable sets and other project features."
  organization = var.organization
  project_id   = tfe_project.project.id

  dynamic "vcs_repo" {
    for_each = var.project_management_vcs != null ? [var.project_management_vcs] : []
    content {
      identifier                 = vcs_repo.value.identifier
      branch                     = try(vcs_repo.value.branch, null)
      oauth_token_id             = try(vcs_repo.value.oauth_token_id, null)
      github_app_installation_id = try(vcs_repo.value.github_app_installation_id, null)
      ingress_submodules         = try(vcs_repo.value.ingress_submodules, null)
      tags_regex                 = try(vcs_repo.value.tags_regex, null)
    }
  }
}

resource "tfe_variable" "project_manager_token" {
  key              = "TFE_TOKEN"
  value_wo         = ephemeral.tfe_team_token.project_manager.token
  value_wo_version = local.token_expiration
  category         = "env"
  workspace_id     = tfe_workspace.project_manager.id
  sensitive        = true
  description      = "Project management team token for ${tfe_project.project.name}"
}

# ── Read-outputs team ─────────────────────────────────────────────────────────

resource "tfe_team" "output_access" {
  name         = "${var.project_name} Project Output Access"
  organization = var.organization
}

# Ephemeral: token generated at apply time, never written to state.
ephemeral "tfe_team_token" "output_access" {
  team_id    = tfe_team.output_access.id
  expired_at = local.token_expiration
}

# "read" access grants visibility into workspace state/outputs for all project workspaces.
resource "tfe_team_project_access" "output_access" {
  team_id    = tfe_team.output_access.id
  project_id = tfe_project.project.id
  access     = "custom"

  project_access {
    settings      = "read"
    teams         = "none"
    variable_sets = "none"
  }

  workspace_access {
    # Allow reading workspace outputs only
    state_versions = "read-outputs"
    sentinel_mocks = "none"
    runs           = "read"
    variables      = "none"

    # Explicitly deny mutating permissions
    create           = false
    locking          = false
    move             = false
    delete           = false
    run_tasks        = false
    policy_overrides = false
  }
}

# ── Project variable set ──────────────────────────────────────────────────────

resource "tfe_variable_set" "output_access" {
  name         = "${tfe_project.project.name} Output Access"
  organization = var.organization
  description  = "Read-outputs token applied to all workspaces in project ${var.project_name}."
}

resource "tfe_variable" "output_access" {
  key              = "TFE_TOKEN"
  value_wo         = ephemeral.tfe_team_token.output_access.token
  value_wo_version = local.token_expiration
  category         = "env"
  variable_set_id  = tfe_variable_set.output_access.id
  sensitive        = true
  description      = "Output Read Access for workspaces in project ${tfe_project.project.name}"
}

resource "tfe_project_variable_set" "output_access" {
  project_id      = tfe_project.project.id
  variable_set_id = tfe_variable_set.output_access.id
}
