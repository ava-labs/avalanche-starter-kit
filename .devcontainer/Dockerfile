# Use Debian Bookworm (stable) - required for docker-in-docker moby support
FROM mcr.microsoft.com/devcontainers/base:bookworm

# Switch to root user to install packages
USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry using foundryup
ENV FOUNDRY_DIR=/home/vscode/.foundry
ENV PATH="${FOUNDRY_DIR}/bin:${PATH}"

# Create foundry directory and set ownership
RUN mkdir -p ${FOUNDRY_DIR}/bin && chown -R vscode:vscode ${FOUNDRY_DIR}

# Switch to vscode user for foundry installation
USER vscode

# Install foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
    ${FOUNDRY_DIR}/bin/foundryup

# Ensure HOME is set correctly
ENV HOME=/home/vscode
