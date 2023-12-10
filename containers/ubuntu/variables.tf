variable "normal_user" {
  description = "Normal user"
  type        = string
  default     = "builder"
}

variable "DEBIAN_FRONTEND" {
  description = "Debian frontend setting"
  type        = string
  default     = "noninteractive"
}

variable "registry_username" {
  description = "The name of the registry username, normally sourced via PKR_VAR"
  type        = string
}

variable "registry_password" {
  description = "The registry password, normally sourced via PKR_VAR"
  type        = string
}

variable "registry" {
  description = "The name of the registry"
  type        = string
  default     = "ghcr.io"
}

variable "org" {
  description = "The name of the organisation, for example, github org"
  type        = string
  default     = "cyber-scot"
}

variable "project" {
  description = "The name of the project, for example, the github repo"
  type        = string
  default     = "base-images"
}

variable "container_name" {
  description = "The name of the container name"
  type        = string
  default     = "ci-cd-base"
}
