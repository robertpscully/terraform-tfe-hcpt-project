output "project_id" {
  value       = tfe_project.this.id
  description = "ID of the created Terraform Cloud project."
}

output "project_name" {
  value       = tfe_project.this.name
  description = "Name of the created Terraform Cloud project."
}

output "workspace_id" {
  value       = tfe_workspace.this.id
  description = "ID of the workspace created inside the project."
}

output "workspace_name" {
  value       = tfe_workspace.this.name
  description = "Name of the workspace created inside the project."
}

output "project_management_team_id" {
  value       = tfe_team.project_management.id
  description = "ID of the project management team."
}

output "read_outputs_team_id" {
  value       = tfe_team.read_outputs.id
  description = "ID of the read-outputs team."
}

output "variable_set_id" {
  value       = tfe_variable_set.this.id
  description = "ID of the project variable set."
}

output "token_rotation_time" {
  value       = time_rotating.token.rotation_rfc3339
  description = "RFC3339 timestamp of the next scheduled token rotation."
}

output "token_last_rotated" {
  value       = time_rotating.token.rfc3339
  description = "RFC3339 timestamp of the last token rotation."
}
