# Avalanche Starter Kit

This repository contains starter code for building cross-chain applications on Avalanche using the Teleporter protocol.

## Prerequisites

- A GitHub account to use Codespaces
- Or locally: [Foundry](https://book.getfoundry.sh/getting-started/installation) and [Git](https://git-scm.com/downloads)

## Setup

1. Open in Codespace:
   - Click the green "Code" button above
   - Select the "Codespaces" tab
   - Click "Create codespace on main"

2. Install dependencies:
```bash
forge install

# Note: You might see a warning about using a nightly build of Foundry. 
# To mute this warning, run:
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1
```

## Wallet Management

1. Create a new wallet:
```bash
cast wallet new
```
You'll receive an output like this:
```
Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

2. Set up your environment:
```bash
# Copy the example environment file
cp .env.example .env
```

Now open the .env file and replace these values with your wallet information from step 1:
- `PK=` : Your private key (the one that starts with 0x...)
- `FUNDED_ADDRESS=` : Your wallet address (the one that starts with 0x...)

Then load the environment variables:
```bash
source .env
```

You can verify the variables are loaded:
```bash
# Should print your address
echo $FUNDED_ADDRESS
# Should print your private key
echo $PK
```

> ⚠️ IMPORTANT: 
> - Never commit your .env file or share your private key
> - The .env file is already in .gitignore for your security
> - Store your private key somewhere secure as backup
> - Example values above are for demonstration only

## Getting Test Tokens

Before deploying contracts, get test tokens from:

1. [Fuji C-Chain Faucet](https://core.app/tools/testnet-faucet/?subnet=c&token=c)
2. [Dispatch Testnet Faucet](https://core.app/tools/testnet-faucet/?subnet=dispatch&token=dispatch)

Check your balance:
```bash
# Check balance on Fuji C-Chain
cast balance $FUNDED_ADDRESS --rpc-url fuji-c

# Check balance on Dispatch
cast balance $FUNDED_ADDRESS --rpc-url fuji-dispatch
```

## Usage

### Deploy Contracts

```bash
# Deploy to Fuji C-Chain
forge create --rpc-url fuji-c \
  --private-key $PK \
  src/contracts/YourContract.sol:YourContract

# Deploy to Dispatch
forge create --rpc-url fuji-dispatch \
  --private-key $PK \
  src/contracts/YourContract.sol:YourContract
```

### Send Transactions

```bash
# Send transaction on Fuji C-Chain
cast send --rpc-url fuji-c \
  --private-key $PK \
  $CONTRACT_ADDRESS "functionName(uint256)" 123

# Send transaction on Dispatch
cast send --rpc-url fuji-dispatch \
  --private-key $PK \
  $CONTRACT_ADDRESS "functionName(uint256)" 123
```

### Read Contract State

```bash
# Read from Fuji C-Chain
cast call --rpc-url fuji-c \
  $CONTRACT_ADDRESS "functionName()(uint256)"

# Read from Dispatch
cast call --rpc-url fuji-dispatch \
  $CONTRACT_ADDRESS "functionName()(uint256)"
```

## Important Notes

1. The Teleporter Registry needs to be predeployed on Dispatch. The address will be either hardcoded or you'll need to deploy it yourself.
2. Make sure to use the correct RPC URLs and contract addresses for your target network.

## Learn More

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Avalanche Documentation](https://docs.avax.network/)
- [Teleporter Documentation](https://docs.avax.network/build/cross-chain/teleporter/overview)
