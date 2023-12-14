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
  default     = "jenkins-alpine-ci-cd-base"
}

variable "license" {
  description = "The license used"
  type        = string
  default     = "MIT"
}

variable "name" {
  description = "The name of the image"
  type        = string
  default     = "jenkins-alpine-cicd-base"
}

variable "normal_user" {
  description = "Normal user"
  type        = string
  default     = "jenkins"
}

variable "org" {
  description = "The name of the organisation, for example, github org"
  type        = string
  default     = "cyber-scot"
}

variable "project_scm" {
  description = "The name of the project, for example, the github repo"
  type        = string
  default     = "https://github.com"
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
  path_var = "/var/jenkins_home:/var/jenkins_home/.local:/var/jenkins_home/.local/bin:/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/home/${var.normal_user}/.local:/home/${var.normal_user}/.tfenv:/home/${var.normal_user}/.tfenv/bin:/home/${var.normal_user}/.pkenv:/home/${var.normal_user}/.pkenv/bin:/home/${var.normal_user}/.pyenv:/home/${var.normal_user}/.pyenv/bin:/home/${var.normal_user}/.pyenv/shims:/home/${var.normal_user}/.local/bin"
  packages = [
    "bash",
    "build-base",
    "bzip2-dev",
    "coreutils",
    "curl",
    "dos2unix",
    "git",
    "icu-libs",
    "jq",
    "libffi-dev",
    "libxml2-dev",
    "libxslt-dev",
    "linux-headers",
    "ncurses-dev",
    "openssl-dev",
    "openssl1.1-compat@edge",
    "readline-dev",
    "sqlite-dev",
    "sudo",
    "tk-dev",
    "xz-dev",
    "xterm"
  ]

  pip_packages = [
    "pip-system-certs",
    "pipenv",
    "virtualenv",
    "terraform-compliance",
    "black",
    "ansible",
    "checkov",
    "pywinrm",
    "azure-cli"
  ]

  jenkins_plugins = [
    "apache-httpcomponents-client-4-api",
    "azure-credentials",
    "azure-ad",
    "bouncycastle-api",
    "caffeine-api",
    "credentials",
    "credentials-binding",
    "display-url-api",
    "git",
    "git-client",
    "instance-identity",
    "jakarta-activation-api",
    "jakarta-mail-api",
    "mailer",
    "mina-sshd-api-common",
    "mina-sshd-api-core",
    "plain-credentials",
    "powershell",
    "scm-api",
    "script-security",
    "ssh-credentials",
    "structs",
    "trilead-api",
    "workflow-scm-step",
    "workflow-step-api"
  ]
}

source "docker" "alpine" {
  image  = "jenkins/jenkins:lts-alpine-jdk21"
  commit = true

  changes = [
    "USER ${var.normal_user}",
    format("LABEL org.opencontainers.image.title=%s", var.container_name),
    format("LABEL org.opencontainers.image.source=%s/%s/%s", var.project_scm, var.org, var.project),
    format("LABEL org.opencontainers.image.title=%s", var.container_name),
    format("ENV PATH=%s", local.path_var),
    format("ENV PYENV_ROOT=%s", "/home/${var.normal_user}/.pyenv"),
  ]

  run_command = ["-d", "-i", "-t", "--user=root", "--entrypoint=/sbin/tini", "--", "{{.Image}}", "--", "/usr/local/bin/jenkins.sh"]
}

build {
  sources = ["source.docker.alpine"]

  provisioner "shell" {
    execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "echo '@edge https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories",
      "apk add --no-cache ${join(" ", local.packages)}",
      "apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust",
      "echo 'PATH=${local.path_var}' > /etc/environment"
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "USER=root"]
    execute_command  = "sudo -Hu root sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "POWERSHELL_RELEASE_URL=$(curl -s -L https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -r '.assets[] | select(.name | endswith(\"linux-musl-x64.tar.gz\")) | .browser_download_url')",
      "curl -L $POWERSHELL_RELEASE_URL -o /tmp/powershell.tar.gz",
      "mkdir -p /opt/microsoft/powershell/7",
      "tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7",
      "chmod +x /opt/microsoft/powershell/7/pwsh",
      "ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh",
      "ln -s /usr/bin/pwsh /usr/bin/powershell"
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "USER=root"]
    execute_command  = "sudo -Hu root sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "git clone https://github.com/pyenv/pyenv.git /home/${var.normal_user}/.pyenv",
      "eval \"$(pyenv init --path)\"",
      "pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E \"^\\s*[0-9]+\\.[0-9]+\\.[0-9]+$\" | tail -1)",
      "pyenv install $pyenvLatestStable",
      "pyenv global $pyenvLatestStable",
      "pip install --upgrade pip",
      "pip install ${join(" ", local.pip_packages)}"
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "USER=root"]
    execute_command  = "sudo -Hu root sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "pwsh -Command Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted",
      "pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery",
      "pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery",
      "pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery"
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "USER=root"]
    execute_command  = "sudo -Hu root sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "git clone --depth=1 https://github.com/tfutils/tfenv.git /home/${var.normal_user}/.tfenv",
      "tfenv install",
      "tfenv use"
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "PYENV_ROOT=/home/${var.normal_user}/.pyenv", "USER=root"]
    execute_command  = "sudo -Hu root sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "curl -sSL $(curl -sSL https://api.github.com/repos/tfsec/tfsec/releases/latest | jq -r '.assets[] | select(.name | contains(\"tfsec-linux-amd64\")) | .browser_download_url') -o /tmp/tfsec > /dev/null 2>&1",
      "chmod +x /tmp/tfsec",
      "mv /tmp/tfsec /usr/local/bin"
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "USER=root"]
    execute_command  = "sudo -Hu root sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "git clone https://github.com/iamhsa/pkenv.git /home/${var.normal_user}/.pkenv",
      "pkenv install latest",
      "pkenv use latest"
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "USER=root"]
    execute_command  = "sudo -Hu root sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "chown -R ${var.normal_user}:${var.normal_user} /opt",
      "chown -R ${var.normal_user}:${var.normal_user} /home/${var.normal_user}",
    ]
  }

  provisioner "shell" {
    environment_vars = ["PATH=${local.path_var}", "PYENV_ROOT=/home/${var.normal_user}/.pyenv"]
    execute_command  = "sudo -Hu ${var.normal_user} sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "jenkins-plugin-cli --plugins ${join(" ", local.jenkins_plugins)}"
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
