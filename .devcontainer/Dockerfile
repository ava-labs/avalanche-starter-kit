FROM --platform=linux/amd64 ghcr.io/foundry-rs/foundry:latest AS foundry
FROM mcr.microsoft.com/devcontainers/base

COPY --from=foundry /usr/local/bin/forge /usr/local/bin/forge
COPY --from=foundry /usr/local/bin/cast /usr/local/bin/cast
COPY --from=foundry /usr/local/bin/anvil /usr/local/bin/anvil
COPY --from=foundry /usr/local/bin/chisel /usr/local/bin/chisel

RUN mkdir -p /home/vscode/.foundry/bin
COPY --from=foundry /usr/local/bin/forge /home/vscode/.foundry/bin/forge

# Switch to root user to install system packages
USER root

# Install Git
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Ensure vscode owns its home directory
RUN chown -R vscode:vscode /home/vscode

# Set HOME environment variable
ENV HOME=/home/vscode

# Switch back to vscode user
USER vscode
