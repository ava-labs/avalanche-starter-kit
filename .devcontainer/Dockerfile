FROM avaplatform/avalanche-cli:v1.8.4 AS avalanche-cli
FROM avaplatform/awm-relayer:latest AS awm-relayer
FROM --platform=linux/amd64 ghcr.io/foundry-rs/foundry:latest AS foundry
FROM mcr.microsoft.com/devcontainers/base

COPY --from=avalanche-cli /avalanche /usr/local/bin/avalanche
COPY --from=awm-relayer /usr/bin/awm-relayer /usr/local/bin/awm-relayer
COPY --from=foundry /usr/local/bin/forge /usr/local/bin/forge
COPY --from=foundry /usr/local/bin/cast /usr/local/bin/cast
COPY --from=foundry /usr/local/bin/anvil /usr/local/bin/anvil
COPY --from=foundry /usr/local/bin/chisel /usr/local/bin/chisel

RUN mkdir -p /home/vscode/.foundry/bin
COPY --from=foundry /usr/local/bin/forge /home/vscode/.foundry/bin/forge

# Switch to root user to install system packages
USER root

# Install Git and other dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Ensure vscode owns its home directory
RUN chown -R vscode:vscode /home/vscode

# Set HOME environment variable
ENV HOME=/home/vscode

# Switch back to vscode user
USER vscode

# Install nvm, Node.js, and TypeScript
ENV NVM_DIR=/home/vscode/.nvm
ENV NODE_VERSION=23.0.0

# Install nvm and Node.js
RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION

# Update PATH for nvm and Node.js
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Install TypeScript globally
RUN npm install -g typescript

# Ensure Node.js and npm are accessible in future shells
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> $HOME/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> $HOME/.bashrc \
    && echo 'export PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"' >> $HOME/.bashrc
