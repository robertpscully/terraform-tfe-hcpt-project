locals {
  workspace_name               = coalesce(var.workspace_name, var.project_name)
  project_management_team_name = coalesce(var.project_management_team_name, "${var.project_name}-project-management")
  read_outputs_team_name       = coalesce(var.read_outputs_team_name, "${var.project_name}-read-outputs")
  variable_set_name            = coalesce(var.variable_set_name, "${var.project_name}-outputs-reader")
}

# ── Token rotation schedule ───────────────────────────────────────────────────

# Replaced automatically after token_rotation_days. Both tfe_variable resources
# use its id as value_wo_version, so replacement triggers ephemeral token regeneration.
# Manual rotation: terraform apply -replace=time_rotating.token
resource "time_rotating" "token" {
  rotation_days = var.token_rotation_days
}

# ── Project ───────────────────────────────────────────────────────────────────

resource "tfe_project" "this" {
  organization = var.organization
  name         = var.project_name
}

# ── Project management team ───────────────────────────────────────────────────

resource "tfe_team" "project_management" {
  name         = local.project_management_team_name
  organization = var.organization
}

# Ephemeral: token generated at apply time, never written to state.
ephemeral "tfe_team_token" "project_management" {
  team_id = tfe_team.project_management.id
}

resource "tfe_team_project_access" "project_management" {
  team_id    = tfe_team.project_management.id
  project_id = tfe_project.this.id
  access     = var.project_management_team_access
}

# ── Workspace ─────────────────────────────────────────────────────────────────

resource "tfe_workspace" "this" {
  name         = local.workspace_name
  organization = var.organization
  project_id   = tfe_project.this.id
}

resource "tfe_variable" "workspace_pm_token" {
  key              = var.workspace_pm_token_key
  value_wo         = ephemeral.tfe_team_token.project_management.token
  value_wo_version = time_rotating.token.id
  category         = var.workspace_pm_token_category
  workspace_id     = tfe_workspace.this.id
  sensitive        = true
  description      = "Project management team token (${local.project_management_team_name})."
}

# ── Read-outputs team ─────────────────────────────────────────────────────────

resource "tfe_team" "read_outputs" {
  name         = local.read_outputs_team_name
  organization = var.organization
}

# Ephemeral: token generated at apply time, never written to state.
ephemeral "tfe_team_token" "read_outputs" {
  team_id = tfe_team.read_outputs.id
}

# "read" access grants visibility into workspace state/outputs for all project workspaces.
resource "tfe_team_project_access" "read_outputs" {
  team_id    = tfe_team.read_outputs.id
  project_id = tfe_project.this.id
  access     = "read"
}

# ── Project variable set ──────────────────────────────────────────────────────

resource "tfe_variable_set" "this" {
  name         = local.variable_set_name
  organization = var.organization
  description  = "Read-outputs token applied to all workspaces in project ${var.project_name}."
}

resource "tfe_variable" "read_outputs_token" {
  key              = var.read_outputs_token_key
  value_wo         = ephemeral.tfe_team_token.read_outputs.token
  value_wo_version = time_rotating.token.id
  category         = var.read_outputs_token_category
  variable_set_id  = tfe_variable_set.this.id
  sensitive        = true
  description      = "Token for ${local.read_outputs_team_name} — read-only workspace outputs."
}

resource "tfe_project_variable_set" "this" {
  project_id      = tfe_project.this.id
  variable_set_id = tfe_variable_set.this.id
}
