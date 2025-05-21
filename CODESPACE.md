# Avalanche Starter Kit - Codespace Guide

This guide provides step-by-step instructions for developing with the Avalanche Starter Kit in GitHub Codespaces.

## Initial Setup

Your Codespace comes pre-configured with:
- Foundry
- Docker support
- Required VS Code extensions
- All necessary development tools

To get started:

1. Install dependencies:
```bash
forge install

# Note: You might see a warning about using a nightly build of Foundry. 
# To mute this warning, run:
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1
```

## Wallet Setup

1. Install Core wallet:
   - Visit [Core wallet website](https://core.app/download)
   - Download and install Core for your operating system
   - Create a new wallet or import an existing one

2. Get your wallet credentials:
   - Open Core wallet
   - Click on your account name in the top right
   - Select "View Private Key"
   - Enter your password when prompted
   - Copy both your:
     - Account address (starts with 0x)
     - Private key (starts with 0x)

> ⚠️ IMPORTANT: 
> - Never share your private key with anyone
> - Keep your private key secure and backed up
> - Only enter your private key in trusted applications

## Environment Setup

1. Set up your environment file:
```bash
# Copy the example environment file
cp .env.example .env
```

2. Edit your `.env` file with your Core wallet credentials:
```bash
# Your Core wallet private key
PK=your_private_key_here
# Your Core wallet address
FUNDED_ADDRESS=your_address_here
# Blockchain IDs in hex format
FUJI_DISPATCH_BLOCKCHAIN_ID_HEX=0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7
FUJI_C_CHAIN_BLOCKCHAIN_ID_HEX=your_c_chain_blockchain_id_here

...
```

3. Load the environment:
```bash
source .env
```

4. Verify your configuration:
```bash
# Should print your Core wallet address
echo $FUNDED_ADDRESS
# Should print your Core wallet private key
echo $PK
```

> ⚠️ SECURITY NOTES: 
> - Never commit your .env file or share your private key
> - The .env file is already in .gitignore for your security
> - Store your Core wallet credentials somewhere secure
> - Example values above are for demonstration only

## Getting Test Tokens

Before deploying contracts, get test tokens using Core wallet:

1. Open Core wallet and switch to Fuji Testnet:
   - Click the network selector (top of the window)
   - Select "Fuji (C-Chain)"

2. Get test tokens:
   - For Fuji C-Chain: Use the [Fuji C-Chain Faucet](https://core.app/tools/testnet-faucet/?subnet=c&token=c) directly in Core
   - For Dispatch: Visit the [Dispatch Testnet Faucet](https://core.app/tools/testnet-faucet/?subnet=dispatch&token=dispatch)

3. Check your balance:
```bash
# Check balance on Fuji C-Chain
cast balance $FUNDED_ADDRESS --rpc-url fuji-c

# Check balance on Dispatch
cast balance $FUNDED_ADDRESS --rpc-url fuji-dispatch
```

## Cross-Chain Contract Deployment

1. Deploy the messaging contracts:
```bash
# Deploy the sender contract on Fuji C-Chain
forge create --rpc-url fuji-c \
  --private-key $PK \
  contracts/interchain-messaging/incentivize-relayer/senderWithFees.sol:SenderWithFeesOnCChain \
  --constructor-args $FUJI_DISPATCH_BLOCKCHAIN_ID_HEX

# Save the sender contract address
export SENDER_ADDRESS="0x..."

# Deploy the receiver contract on Dispatch
forge create --rpc-url fuji-dispatch \
  --private-key $PK \
  contracts/interchain-messaging/incentivize-relayer/receiverWithFees.sol:ReceiverOnDispatch

# Save the receiver contract address
export RECEIVER_ADDRESS="0x..."
```

2. Approve tokens for the sender contract:
```bash
# Approve the sender contract to spend your FEE tokens
# The amount 500000000000000000 is 0.5 FEE tokens (the required fee amount)
cast send --rpc-url fuji-c \
  --private-key $PK \
  $FEE_TOKEN_ADDRESS \
  "approve(address,uint256)" \
  $SENDER_ADDRESS \
  500000000000000000
```

3. Create the relayer configuration:
```bash
mkdir -p config
cat > config/config.json << EOL
{
    "logLevel": "info",
    "chains": [
        {
            "chainID": "$FUJI_C_CHAIN_BLOCKCHAIN_ID_HEX",
            "endpoint": "https://api.avax-test.network/ext/bc/C/rpc",
            "from": "$FUNDED_ADDRESS",
            "privateKey": "$PK"
        },
        {
            "chainID": "$FUJI_DISPATCH_BLOCKCHAIN_ID_HEX",
            "endpoint": "https://subnets.avax.network/dispatch/testnet/rpc",
            "from": "$FUNDED_ADDRESS",
            "privateKey": "$PK"
        }
    ]
}
EOL
```

4. Run the relayer:
```bash
docker run -v $(pwd)/config:/app/config \
    ghcr.io/ava-labs/icm-relayer:latest \
    --config /app/config/config.json
```

## Testing Cross-Chain Messaging with Fees

After setting up the contracts and relayer, you can test the cross-chain messaging:

1. Send a message from Fuji to Dispatch:
```bash
# Send a message through the sender contract
cast send --rpc-url fuji-c \
  --private-key $PK \
  $SENDER_ADDRESS \
  "sendMessage(address,string,address)" \
  $RECEIVER_ADDRESS \
  "Hello from Fuji with fees!" \
  $FEE_TOKEN_ADDRESS
```

2. Check the received message:
```bash
# Wait a few moments for the message to be relayed
cast call --rpc-url fuji-dispatch \
  $RECEIVER_ADDRESS \
  "lastMessage()(string)"
```

## Contract Deployment

```bash
# Deploy to Fuji C-Chain
forge create --rpc-url fuji-c \
  --private-key $PK \
  src/contracts/YourContract.sol:YourContract \
  --constructor-args $FUJI_C_CHAIN_BLOCKCHAIN_ID_HEX

# Deploy to Dispatch
forge create --rpc-url fuji-dispatch \
  --private-key $PK \
  src/contracts/YourContract.sol:YourContract \
  --constructor-args $FUJI_DISPATCH_BLOCKCHAIN_ID_HEX
```

## Sending Cross-Chain Messages

```bash
# Send message from Fuji C-Chain to Dispatch
cast send --rpc-url fuji-c \
  --private-key $PK \
  $CONTRACT_ADDRESS "sendMessage(string)" "Hello Dispatch!"

# Send message from Dispatch to Fuji C-Chain
cast send --rpc-url fuji-dispatch \
  --private-key $PK \
  $CONTRACT_ADDRESS "sendMessage(string)" "Hello Fuji!"
```

## Reading Contract State

```bash
# Read from Fuji C-Chain
cast call --rpc-url fuji-c \
  $CONTRACT_ADDRESS "getLastMessage()(string)"

# Read from Dispatch
cast call --rpc-url fuji-dispatch \
  $CONTRACT_ADDRESS "getLastMessage()(string)"
```

## Development Tips

1. The devcontainer comes with Docker support, allowing you to run the ICM relayer directly in your Codespace
2. Use environment variables for blockchain IDs and other network-specific values
3. Always test cross-chain messaging with small transactions first
4. Monitor the ICM relayer logs for message delivery status
5. Use VS Code's integrated terminal for all commands
6. The Git integration in Codespaces allows for easy commits and pushes

## Troubleshooting

1. If you see Docker permission errors:
   - The container will automatically restart
   - Your Docker daemon is already configured correctly

2. If environment variables are not loading:
   - Make sure to run `source .env` in each new terminal
   - Verify the .env file exists and has the correct values

3. If the relayer isn't connecting:
   - Check your blockchain IDs are correct
   - Verify your wallet has sufficient funds
   - Ensure your RPC endpoints are accessible

4. For contract deployment issues:
   - Verify your private key is set correctly
   - Check that you have sufficient funds
   - Ensure all constructor arguments are provided 