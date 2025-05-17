# Avalanche Smart Contract Development Kit

This development kit provides a minimal setup for developing and deploying Solidity smart contracts on Avalanche networks using Foundry. It includes:

- **Foundry**:
  - Forge: Compile and deploy smart contracts to Fuji Testnet
  - Cast: Interact with deployed contracts

## Set Up

This kit utilizes a Dev Container specification for a consistent and isolated development environment. The container includes Foundry pre-installed and configured. You can run it using GitHub Codespaces or locally using Docker and VS Code.

### Run on Github Codespace

You can run directly on Github by clicking **Code**, switching to the **Codespaces** tab and clicking **Create codespace on main**. A new window will open with VS Code and all dependencies installed.

### Run Dev Container locally with Docker

To run locally, you need:
1. [Docker](https://www.docker.com/products/docker-desktop/) installed
2. [VS Code](https://code.visualstudio.com/) with the [Dev Container extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

Clone the repository and open it in VS Code. VS Code will ask you if you want to reopen the project in a container.

## Using Foundry

The environment is configured with RPC endpoints for Fuji testnet and Dispatch. You can find these configurations in `foundry.toml`:

```toml
[rpc_endpoints]
fuji-c = "https://api.avax-test.network/ext/bc/C/rpc"
dispatch = "https://subnets.avax.network/dispatch/testnet/rpc"
```

### Common Commands

1. **Deploying Smart Contracts**
```bash
forge create --rpc-url fuji-c --private-key $PK path/to/Contract.sol:ContractName
```

2. **Making State-Changing Calls**
```bash
cast send --rpc-url fuji-c --private-key $PK <CONTRACT_ADDRESS> "functionName(uint256)" 123
```

3. **Making Read-Only Calls**
```bash
cast call --rpc-url fuji-c <CONTRACT_ADDRESS> "viewFunction()(uint256)"
```

## Contract Examples

You can find example contracts in the `contracts/` directory. These contracts demonstrate various smart contract patterns and functionalities.
