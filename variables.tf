variable "organization" {
  type        = string
  description = "Name of the Terraform Cloud organization."
}

variable "project_name" {
  type        = string
  description = "Name of the Terraform Cloud project to create."
}

variable "workspace_name" {
  type        = string
  description = "Name of the workspace to create inside the project. Defaults to project_name."
  default     = null
}

variable "project_management_team_name" {
  type        = string
  description = "Name of the team used for project management. Defaults to '<project_name>-project-management'."
  default     = null
}

variable "project_management_team_access" {
  type        = string
  description = "Project access level granted to the project management team."
  default     = "maintain"

  validation {
    condition     = contains(["admin", "maintain", "write", "read"], var.project_management_team_access)
    error_message = "Must be one of: admin, maintain, write, read."
  }
}

variable "workspace_pm_token_key" {
  type        = string
  description = "Variable key used to embed the project management team token in the workspace."
  default     = "TFE_TOKEN"
}

variable "workspace_pm_token_category" {
  type        = string
  description = "Category for the embedded project management token variable (env or terraform)."
  default     = "env"

  validation {
    condition     = contains(["env", "terraform"], var.workspace_pm_token_category)
    error_message = "Must be env or terraform."
  }
}

variable "read_outputs_team_name" {
  type        = string
  description = "Name of the team with read-only access to project workspace outputs. Defaults to '<project_name>-read-outputs'."
  default     = null
}

variable "variable_set_name" {
  type        = string
  description = "Name of the project variable set containing the read-outputs token. Defaults to '<project_name>-outputs-reader'."
  default     = null
}

variable "read_outputs_token_key" {
  type        = string
  description = "Variable key for the read-outputs token in the project variable set."
  default     = "TFE_OUTPUTS_TOKEN"
}

variable "read_outputs_token_category" {
  type        = string
  description = "Category for the read-outputs token variable (env or terraform)."
  default     = "env"

  validation {
    condition     = contains(["env", "terraform"], var.read_outputs_token_category)
    error_message = "Must be env or terraform."
  }
}

variable "token_rotation_days" {
  type        = number
  description = "Number of days between automatic token rotations. Tokens rotate on the next apply after the period expires."
  default     = 30

  validation {
    condition     = var.token_rotation_days > 0
    error_message = "token_rotation_days must be a positive integer."
  }
}

variable "project_management_vcs" {
  type = object({
    identifier                 = string
    branch                     = string
    oauth_token_id             = string
    github_app_installation_id = string
    ingress_submodules         = bool
    tags_regex                 = string
  })
  description = <<-EOT
    Optional VCS repository configuration for the project management workspace.
    Set this variable to an object with the following named keys to enable VCS-backed runs:
      - identifier (required when enabling): "<org>/<repo>"
      - branch: branch to use (default: repository default)
      - oauth_token_id: oauth client token id (GitHub OAuth token ID)
      - github_app_installation_id: GitHub App installation id (mutually exclusive with oauth_token_id)
      - ingress_submodules: boolean to fetch submodules
      - tags_regex: regex for tag-triggered runs

    Leave as `null` (default) to disable VCS configuration.
  EOT
  default     = null
}
