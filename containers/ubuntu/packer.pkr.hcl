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

variable "license" {
  description = "The license used"
  type        = string
  default     = "MIT"
}

variable "name" {
  description = "The name of the image"
  type        = string
  default     = "cicd-base"
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

variable "repository" {
  description = "The name of the base repository"
  type        = string
  default     = "https://github.com"
}

variable "tags" {
  description = "The list of tags to deploy"
  type        = list(string)
  default     = ["latest"]
}

source "docker" "ubuntu" {
  image  = "ubuntu:latest"
  commit = true

  changes = [
    "LABEL org.opencontainers.image.source=${var.repository_name}/${var.org}/${var.project}",
    "LABEL org.opencontainers.image.description=${var.name}",
    "LABEL org.opencontainers.image.licenses=${var.license}"
  ]
}

build {
  sources = ["source.docker.ubuntu"]

  provisioner "shell" {
    inline = [
      "rm -rf /bin/sh && ln -sf /bin/bash /bin/sh",
      "apt-get update",
      "apt-get install -y software-properties-common",
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = format("%s/%s/%s/%s", var.registry, var.org, var.project, var.name)
      tags       = distinct(var.tags)
    }

    post-processor "docker-push" {
      login          = true
      login_server   = var.registry
      login_username = var.registry_username
      login_password = var.registry_password
    }
  }
}
