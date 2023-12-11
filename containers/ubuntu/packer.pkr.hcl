packer {
  required_plugins {
    docker = {
      version = "~> 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
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

locals {
  path_var = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/home/${var.normal_user}/.local:/home/${var.normal_user}/.tfenv:/home/${var.normal_user}/.tfenv/bin:/home/${var.normal_user}/.pkenv:/home/${var.normal_user}/.pkenv/bin:/home/${var.normal_user}/.pyenv:/home/${var.normal_user}/.pyenv/bin:/home/${var.normal_user}/.pyenv/shims:/home/${var.normal_user}/.local/bin"
  apt_packages = [
    "apt-transport-https",
    "bash",
    "libbz2-dev",
    "ca-certificates",
    "curl",
    "gcc",
    "gnupg",
    "gnupg2",
    "git",
    "jq",
    "libffi-dev",
    "libicu-dev",
    "make",
    "software-properties-common",
    "libsqlite3-dev",
    "libssl-dev",
    "unzip",
    "wget",
    "zip",
    "zlib1g-dev",
    "build-essential",
    "sudo",
    "libreadline-dev",
    "llvm",
    "libncurses5-dev",
    "xz-utils",
    "tk-dev",
    "libxml2-dev",
    "libxmlsec1-dev",
    "liblzma-dev"
  ]
}

source "docker" "ubuntu" {
  image  = "ubuntu:latest"
  commit = true

  changes = [
    format("LABEL org.opencontainers.image.title=%s", var.container_name),
    format("LABEL org.opencontainers.image.source=%s/%s/%s", var.registry, var.org, var.project),
    format("LABEL org.opencontainers.image.title=%s", var.container_name),
    format("ENV PATH=%s", local.path_var),
    format("ENV DEBIAN_FRONTEND=%s", "noninteractive")
  ]
}

build {
  sources = ["source.docker.ubuntu"]

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "rm -rf /bin/sh && ln -sf /bin/bash /bin/sh",
      "useradd -ms /bin/bash ${var.normal_user}",
      "mkdir -p /home/linuxbrew",
      "chown -R ${var.normal_user}:${var.normal_user} /home/linuxbrew",
      "apt-get update",
      "apt-get dist-upgrade -y",
      "apt-get install -y ${join(" ", local.apt_packages)}",
      "echo 'PATH=${local.path_var}' > /etc/environment"
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
