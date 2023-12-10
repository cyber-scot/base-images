packer {
  required_plugins {
    docker = {
      version = "~> 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "DEBIAN_FRONTEND" {
  description = "Debian frontend setting"
  type        = string
  default     = "noninteractive"
}

variable "container_name" {
  description = "The name of the container name"
  type        = string
  default     = "ci-cd-base"
}

variable "normal_user" {
  description = "Normal user"
  type        = string
  default     = "builder"
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

variable "registry" {
  description = "The name of the registry"
  type        = string
  default     = "ghcr.io"
}

variable "registry_password" {
  description = "The registry password, normally sourced via PKR_VAR"
  type        = string
}

variable "registry_username" {
  description = "The name of the registry username, normally sourced via PKR_VAR"
  type        = string
}

variable "tags" {
  description = "The list of tags to deploy"
  type        = list(string)
  default     = ["latest"]
}

source "docker" "ubuntu" {
  image  = "ubuntu:latest"
  commit = true
}

build {
  sources = ["source.docker.ubuntu"]

  provisioner "shell" {
    inline = [
      "rm -rf /bin/sh && ln -sf /bin/bash /bin/sh",
      "apt-get update",
      "apt-get install -y software-properties-common",
      // Add other provisioning commands here
    ]
  }

  post-processor "docker-tag" {
    repository = format("%s/%s/%s", var.registry, var.org, var.project)
    tags       = distinct(var.tags)
  }

  post-processor "docker-push" {
    login          = true
    login_server   = var.registry
    login_username = var.registry_username
    login_password = var.registry_password
  }
}
