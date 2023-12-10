packer {
  required_plugins {
    docker = {
      version = "~> 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

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
    repository = "ghcr.io/your-username/repository-name"
    tag        = "latest"
  }

  post-processor "docker-push" {
    login       = true
    login_server = "ghcr.io"
    login_username = "your-username"
    login_password = "your-password"
  }
}
