# Instructions - Send & Receive

The following code example will show you how to send, receive and verify the receival of messages using teleporter and foundry. It includes instructions for the [local network](#local-network) and [fuji testnet](#fuji-testnet).

## Local Network

For convenience the private key `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` of the default airdrop address is stored in the environment variable `$PK`. Furthermore, the RPC-url for the C-Chain of your local network is set in the `foundry.toml` file.

## Subnet Configuration

To get started, create a Subnet configuration named "mysubnet":

```zsh
avalanche subnet create mysubnet
```

Your Subnet should have Teleporter enabled, the CLI should run an AWM Relayer, and upon Subnet deployment, 1,000,000 tokens should be airdropped to the default ewoq address:

```zsh
? Choose your VM:
✔ Subnet-EVM
? What version of Subnet-EVM would you like?:
✔ Use latest release version
? Would you like to enable Teleporter on your VM?:
✔ Yes
? Would you like to run AMW Relayer when deploying your VM?:
✔ Yes
Installing subnet-evm-v0.6.4...
subnet-evm-v0.6.4 installation successful
creating genesis for subnet mysubnet
Enter your subnet's ChainId. It can be any positive integer.
ChainId: 012345
Select a symbol for your subnet's native token
Token symbol: NATV
? How would you like to set fees:
✔ Low disk use    / Low Throughput    1.5 mil gas/s (C-Chain's setting)
? How would you like to distribute funds:
✔ Airdrop 1 million tokens to the default ewoq address (do not use in production)
prefunding address 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC with balance 1000000000000000000000000
? Advanced: Would you like to add a custom precompile to modify the EVM?:
✔ No
✓ Successfully created subnet configuration
```

Finally, deploy your Subnet:

```zsh
avalanche subnet deploy mysubnet
```

```zsh
? Choose a network for the operation:
✔ Local Network
Deploying [mysubnet] to Local Network
```

### Setting the Blockchain ID in the Contracts

Make sure to replace the blockchainID in the sender contract `src/0-send-receive/extendedSenderOnCChain.sol` with the ID of your Subnet's blockchain.

> :no_entry_sign: blockchainID of Subnet ≠ chainID of Subnet

You can find the blockchainID of your Subnet with this command:

```bash
avalanche subnet describe mysubnet
```

Take the HEX blockchain ID and replace it sender contract:

```solidity
teleporterMessenger.sendCrossChainMessage(
    TeleporterMessageInput({
        // Replace with blockchainID of your Subnet (see instructions in Readme)
        destinationBlockchainID: 0x92756d698399805f0088fc07fc42af47c67e1d38c576667ac6c7031b8df05293,
        destinationAddress: destinationAddress,
        
        // ...
    })
);
```

### Deploying the Contracts

After adapting the contracts you can deploy them with `forge create`:

```bash
forge create --rpc-url local-c --private-key $PK src/0-send-receive/extendedSenderOnCChain.sol:SenderOnCChain

```

Then save the sender contract address (displayed in `Deployed To:`) in an environment variable:

```bash
export SENDER_ADDRESS=0x123...
```


```bash
forge create --rpc-url mysubnet --private-key $PK src/0-send-receive/extendedReceiverOnSubnet.sol:ReceiverOnSubnet
```

Now, save the receiver contract address (displayed in `Deployed To:`) in an environment variable:

```bash
export RECEIVER_ADDRESS=0x123...
```

### Sending a Message

```bash
cast send --rpc-url local-c --private-key $PK $SENDER_ADDRESS "sendMessage(address,string)" $RECEIVER_ADDRESS "Hello"
```

### Verifying Message Receipt

```bash
cast call --rpc-url mysubnet $RECEIVER_ADDRESS "lastMessage()(string)"
```
