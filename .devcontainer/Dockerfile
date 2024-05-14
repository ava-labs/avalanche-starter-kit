FROM avaplatform/avalanche-cli:latest as avalanche-cli
FROM avaplatform/awm-relayer:latest as awm-relayer
FROM ghcr.io/foundry-rs/foundry:latest as foundry
FROM mcr.microsoft.com/devcontainers/base

COPY --from=avalanche-cli /avalanche /usr/local/bin/avalanche

COPY --from=awm-relayer /usr/bin/awm-relayer /usr/local/bin/awm-relayer

COPY --from=foundry /usr/local/bin/forge /usr/local/bin/forge
COPY --from=foundry /usr/local/bin/cast /usr/local/bin/cast
COPY --from=foundry /usr/local/bin/anvil /usr/local/bin/anvil
COPY --from=foundry /usr/local/bin/chisel /usr/local/bin/chisel
