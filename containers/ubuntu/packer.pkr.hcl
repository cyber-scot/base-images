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
  default     = "ubuntu-ci-cd-base"
}

variable "license" {
  description = "The license used"
  type        = string
  default     = "MIT"
}

variable "name" {
  description = "The name of the image"
  type        = string
  default     = "ubuntu-cicd-base"
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
    format("ENV NORMAL_USER_HOME=/home/%s", var.normal_user),
    format("ENV DEBIAN_FRONTEND=%s", "noninteractive"),
    format("ENV PYENV_ROOT=%s", "/home/${var.normal_user}/.pyenv"),
    "ENV $PYENV_ROOT/shims:$PYENV_ROOT/bin:${local.path_var}",
    "USER ${var.normal_user}",
    "WORKDIR /home/${var.normal_user}"
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

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "PATH=${local.path_var}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "git clone https://github.com/pyenv/pyenv.git /home/${var.normal_user}/.pyenv",
      "eval \"$(pyenv init --path)\"",
      "pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E \"^\\s*[0-9]+\\.[0-9]+\\.[0-9]+$\" | tail -1)",
      "pyenv install $pyenvLatestStable",
      "pyenv global $pyenvLatestStable",
      "pip install --upgrade pip"
    ]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "curl -sSLO https://packages.microsoft.com/config/ubuntu/$(grep -oP '(?<=^DISTRIB_RELEASE=).+' /etc/lsb-release | tr -d '\"')/packages-microsoft-prod.deb",
      "dpkg -i packages-microsoft-prod.deb",
      "rm -f packages-microsoft-prod.deb",
      "apt-get update",
      "apt-get install -y powershell",
      "ln -sf /usr/bin/pwsh /usr/bin/powershell"
    ]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "pwsh -Command Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted",
      "pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery",
      "pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery",
      "pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery"
    ]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "PATH=${local.path_var}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "git clone --depth=1 https://github.com/tfutils/tfenv.git /home/${var.normal_user}/.tfenv",
      "tfenv install",
      "tfenv use"
    ]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "PATH=${local.path_var}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "git clone https://github.com/iamhsa/pkenv.git /home/${var.normal_user}/.pkenv",
      "pkenv install latest",
      "pkenv use latest"
    ]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "PATH=${local.path_var}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "chown -R ${var.normal_user}:${var.normal_user} /opt",
      "chown -R ${var.normal_user}:${var.normal_user} /home/${var.normal_user}",
      "apt-get update",
      "apt-get autoremove -y",
      "apt-get clean",
      "rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"
    ]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "PATH=${local.path_var}", "USER=${var.normal_user}", "PYENV_ROOT=/home/${var.normal_user}/.pyenv"]
    execute_command  = "sudo -Hu ${var.normal_user} sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "eval \"$(pyenv init --path)\"",
      "pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E \"^\\s*[0-9]+\\.[0-9]+\\.[0-9]+$\" | tail -1)",
      "pyenv install $pyenvLatestStable",
      "pyenv global $pyenvLatestStable",
      "pip install --upgrade pip",
      "pip install --user pipenv virtualenv terraform-compliance checkov pywinrm",
      "pip install --user azure-cli"
    ]
  }


  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "PATH=${local.path_var}", "USER=${var.normal_user}", "PYENV_ROOT=/home/${var.normal_user}/.pyenv"]
    execute_command  = "sudo -Hu ${var.normal_user} sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "echo -en '\\n' | /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      "echo 'eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> /home/${var.normal_user}/.bashrc",
      "eval \"$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"",
      "brew install gcc",
      "brew install tfsec"
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
