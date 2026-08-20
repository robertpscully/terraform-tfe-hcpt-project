output "project" {
  value = {
    name = tfe_project.project.name
    id   = tfe_project.project.id
  }
  description = "ID of the created Terraform Cloud project."
}

output "project_manager_workspace" {
  value = {
    name = tfe_workspace.project_manager.name
    id   = tfe_workspace.project_manager.id
  }
  description = "Details of workspace for managing the project."
}

output "project_manager_team" {
  value = {
    name         = tfe_team.project_manager.name
    id           = tfe_team.project_manager.id
    token_expiry = local.token_expiration
  }
  description = "Details of IAC team used for project management."
}

output "output_access" {
  value = {
    id           = tfe_team.output_access.id
    name         = tfe_team.output_access.name
    token_expire = local.token_expiration
    variable_set = tfe_variable_set.output_access.id

  }
  description = "Details of the cross workspace output access configuration."
}

