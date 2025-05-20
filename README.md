# Avalanche Starter Kit

This repository contains starter code for building cross-chain applications on Avalanche using the Teleporter protocol.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)

## Setup

1. Clone the repository:
```bash
git clone https://github.com/ava-labs/avalanche-starter-kit.git
cd avalanche-starter-kit
```

2. Install dependencies:
```bash
forge install
```

## Wallet Management

We use Foundry's built-in wallet management system for secure key handling:

1. Create a new wallet:
```bash
cast wallet new my-avalanche-wallet
```
This creates a wallet stored securely in `~/.foundry/wallets/my-avalanche-wallet`

2. Get your wallet address:
```bash
cast wallet address my-avalanche-wallet
```

3. Use your wallet's private key in commands:
```bash
--private-key $(cast wallet private-key my-avalanche-wallet)
```

## Getting Test Tokens

Before deploying contracts, get test tokens from:

1. [Fuji C-Chain Faucet](https://core.app/tools/testnet-faucet/?subnet=c&token=c)
2. [Dispatch Testnet Faucet](https://core.app/tools/testnet-faucet/?subnet=dispatch&token=dispatch)

Check your balance:
```bash
cast balance $(cast wallet address my-avalanche-wallet) --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

## Environment Setup

Create a `.env` file with the following variables:

```bash
# RPC URLs
FUJI_RPC_URL=https://api.avax-test.network/ext/bc/C/rpc
DISPATCH_RPC_URL=https://subnets.avax.network/dispatch/testnet/rpc

# Blockchain IDs
FUJI_CHAIN_ID=43113
DISPATCH_CHAIN_ID=0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7

# Contract Addresses
TELEPORTER_REGISTRY_FUJI=0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228
TELEPORTER_MESSENGER_DISPATCH=0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf
```

## Usage

### Deploy Contracts

```bash
forge create --rpc-url $FUJI_RPC_URL \
  --private-key $(cast wallet private-key my-avalanche-wallet) \
  src/contracts/YourContract.sol:YourContract
```

### Send Transactions

```bash
cast send --rpc-url $FUJI_RPC_URL \
  --private-key $(cast wallet private-key my-avalanche-wallet) \
  $CONTRACT_ADDRESS "functionName(uint256)" 123
```

### Read Contract State

```bash
cast call --rpc-url $FUJI_RPC_URL \
  $CONTRACT_ADDRESS "functionName()(uint256)"
```

## Important Notes

1. The Teleporter Registry needs to be predeployed on Dispatch. The address will be either hardcoded or you'll need to deploy it yourself.
2. Make sure to use the correct RPC URLs and contract addresses for your target network.
3. Never commit your `.env` file or expose your private keys.

## Learn More

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Avalanche Documentation](https://docs.avax.network/)
- [Teleporter Documentation](https://docs.avax.network/build/cross-chain/teleporter/overview)
