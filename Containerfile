FROM ubuntu:24.04

LABEL com.github.containers.toolbox="true"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get update && apt-get install -y \
    # Essential tools
    curl \
    wget \
    git \
    vim \
    nano \
    less \
    man \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    \
    # Development tools
    build-essential \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    \
    # Network tools
    ssh \
    openssh-client \
    dnsutils \
    net-tools \
    iputils-ping \
    \
    # System tools
    systemd \
    systemd-sysv \
    libsystemd0 \
    dbus \
    polkitd \
    \
    # Container tools (for Docker/Podman access from inside)
    uidmap \
    slirp4netns \
    fuse-overlayfs \
    \
    # Terminal UI support
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set up locales
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Node.js 20.x (for better compatibility with opencode)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install opencode
RUN npm install -g opencode-ai

# Create agentbox user (matching host user will be created at runtime)
RUN useradd -m -s /bin/bash -G sudo agentboxuser && \
    echo '%sudo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/agentbox-sudo && \
    chmod 0440 /etc/sudoers.d/agentbox-sudo

# Ensure /home is empty (required for Toolbx compatibility)
RUN rm -rf /home/*

# Create required directories for agentbox
RUN mkdir -p /usr/share/empty && \
    mkdir -p /etc/krb5.conf.d && \
    mkdir -p /etc/ld.so.conf.d && \
    mkdir -p /etc/pkcs11/modules && \
    mkdir -p /usr/lib/rpm/macros.d && \
    mkdir -p /etc/profile.d

# Set up VTE support for terminal emulators
RUN echo 'if [ -f /etc/profile.d/vte.sh ]; then . /etc/profile.d/vte.sh; fi' > /etc/profile.d/vte-agentbox.sh

# Toolbox environment marker
ENV TOOLBOX_PATH=/run/.toolboxenv

# Entry point will be set by agentbox at runtime
# DO NOT set ENTRYPOINT here (per Toolbx requirements)

# Default command
CMD ["/bin/bash"]
