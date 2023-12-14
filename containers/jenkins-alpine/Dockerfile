FROM docker.io/jenkins/jenkins:lts-alpine-jdk21

LABEL org.opencontainers.image.title=jenkins-alpine-cicd-base
LABEL org.opencontainers.image.source=https://github.com/cyber-scot/base-images

#Set args with blank values - these will be over-written with the CLI
ARG NORMAL_USER=jenkins

# Environment variables for pyenv
ENV PYENV_ROOT /opt/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

#Set path vars
ENV PATH="/var/jenkins_home:/var/jenkins_home/.local:/var/jenkins_home/.local/bin:/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/var/jenkins_home/.local:/home/${NORMAL_USER}:/opt/.tfenv:/opt/.tfenv/bin:/opt/.pkenv:/opt/.pkenv/bin:/opt/.pyenv:/opt/.pyenv/bin:/opt/.pyenv/shims:/opt/.local/bin"
ENV PATHVAR="PATH=${PATH}"

USER root

RUN echo '@edge https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    apk add --no-cache \
    bash \
    build-base \
    bzip2-dev \
    coreutils \
    curl \
    dos2unix \
    git \
    icu-libs \
    jq \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    ncurses-dev \
    openssl-dev \
    openssl1.1-compat@edge \
    readline-dev \
    sqlite-dev \
    sudo \
    tk-dev \
    xterm \
    xz-dev && \
    apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust && \
    echo $PATHVAR > /etc/environmentecho $PATHVAR > /etc/environment

RUN chown -R ${NORMAL_USER}:${NORMAL_USER} /opt

# Download the PowerShell '.tar.gz' archive
RUN POWERSHELL_RELEASE_URL=$(curl -s -L https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -r '.assets[] | select(.name | endswith("linux-musl-x64.tar.gz")) | .browser_download_url') && \
    curl -L $POWERSHELL_RELEASE_URL -o /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    ln -s /usr/bin/pwsh /usr/bin/powershell

#Install Azure Modules for Powershell - This can take a while, so setting as final step to shorten potential rebuilds
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted && \
    pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery

RUN mkdir -p /opt/tfsec && \
    curl -sSL $(curl -sSL https://api.github.com/repos/tfsec/tfsec/releases/latest | jq -r '.assets[] | select(.name | contains("tfsec-linux-amd64")) | .browser_download_url') -o /tmp/tfsec > /dev/null 2>&1 && \
    chmod +x /tmp/tfsec && \
    mv /tmp/tfsec /opt/tfsec/tfsec && \
    ln -fs /opt/tfsec/tfsec /usr/bin/tfsec

USER ${NORMAL_USER}
WORKDIR /var/jenkins_home

## Install pyenv and the latest stable version of Python
RUN git clone https://github.com/pyenv/pyenv.git /opt/.pyenv && \
    eval "$(pyenv init --path)" && \
    pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tail -1) && \
    pyenv install $pyenvLatestStable && \
    pyenv global $pyenvLatestStable && \
    pip install --upgrade pip && \
    pip install \
    pip-system-certs \
    ansible \
    azure-cli \
    pipenv \
    virtualenv \
    terraform-compliance \
    checkov \
    pywinrm

RUN git clone --depth=1 https://github.com/tfutils/tfenv.git /opt/.tfenv && \
    tfenv install && \
    tfenv use

# Install Packer Env
RUN git clone https://github.com/iamhsa/pkenv.git /opt/.pkenv && \
    PACKER_LATEST_URL=$(curl -sL https://releases.hashicorp.com/packer/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|beta|alpha' | egrep 'linux.*amd64'  | tail -1) && \
    PACKER_LATEST_VERSION=$(echo "$PACKER_LATEST_URL" | awk -F '/' '{print $6}' | sed 's/packer_//' | sed 's/_linux_amd64.zip//') && \
    cd /opt/.pkenv && \
    pkenv install ${PACKER_LATEST_VERSION} && \
    pkenv use ${PACKER_LATEST_VERSION}

RUN jenkins-plugin-cli --plugins \
    apache-httpcomponents-client-4-api \
    azure-credentials \
    azure-ad \
    bouncycastle-api \
    caffeine-api \
    credentials \
    credentials-binding \
    display-url-api \
    git \
    git-client \
    instance-identity \
    jakarta-activation-api \
    jakarta-mail-api \
    mailer \
    mina-sshd-api-common \
    mina-sshd-api-core \
    plain-credentials \
    powershell \
    scm-api \
    script-security \
    ssh-credentials \
    structs \
    trilead-api \
    workflow-scm-step \
    workflow-step-api
