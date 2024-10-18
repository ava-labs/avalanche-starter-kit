FROM avaplatform/avalanchego:v1.12.0-initial-poc.5 as avalanchego
FROM avaplatform/avalanche-cli:v1.8.0-rc0 as avalanche-cli
FROM avaplatform/awm-relayer:latest as awm-relayer
FROM --platform=linux/amd64 ghcr.io/foundry-rs/foundry:latest as foundry
FROM mcr.microsoft.com/devcontainers/base

COPY --from=avalanche-cli /avalanche /usr/local/bin/avalanche
COPY --from=avalanchego /avalanchego/build/avalanchego /usr/local/bin/avalanchego

COPY --from=awm-relayer /usr/bin/awm-relayer /usr/local/bin/awm-relayer

COPY --from=foundry /usr/local/bin/forge /usr/local/bin/forge
COPY --from=foundry /usr/local/bin/cast /usr/local/bin/cast
COPY --from=foundry /usr/local/bin/anvil /usr/local/bin/anvil
COPY --from=foundry /usr/local/bin/chisel /usr/local/bin/chisel

RUN mkdir -p /home/vscode/.foundry/bin
COPY --from=foundry /usr/local/bin/forge /home/vscode/.foundry/bin/forge

