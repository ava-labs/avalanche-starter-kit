# Avalanche Starter Kit

This repository contains starter code for building cross-chain applications on Avalanche using the Teleporter protocol and ICM (Inter-Chain Messaging).

## Getting Started

This repository is optimized for development in GitHub Codespaces, providing a pre-configured environment with all necessary tools and dependencies.

### Option 1: GitHub Codespaces (Recommended)

1. Click the green "Code" button above
2. Select the "Codespaces" tab
3. Click "Create codespace on main"
4. Follow the instructions in [CODESPACE.md](./CODESPACE.md)

### Option 2: Local Development

For local development instructions and setup, see [LOCAL.md](./LOCAL.md)

## Features

- Cross-chain messaging using Teleporter and ICM protocols
- Pre-configured development environment
- Example contracts for cross-chain communication
- Automated relayer setup for message passing
- Built-in Docker support for running services
- Foundry-based testing and deployment

## Architecture

The starter kit demonstrates cross-chain communication between:
- Avalanche Fuji C-Chain (testnet)
- Avalanche Dispatch Chain (testnet)

Messages can be sent bidirectionally between these chains using either:
- Teleporter Protocol
- ICM (Inter-Chain Messaging)

## Learn More

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Avalanche Documentation](https://docs.avax.network/)
- [Teleporter Documentation](https://docs.avax.network/build/cross-chain/teleporter/overview)
- [ICM Documentation](https://docs.avax.network/build/cross-chain/icm/overview)
