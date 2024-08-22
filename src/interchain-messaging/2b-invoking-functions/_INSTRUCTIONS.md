# Instructions - Invoking Functions (Multi-function)

The following code example will show you how to send a roundtrip message and verify the receival of messages using teleporter and foundry. It includes instructions for the [local network](#local-network).

## Local Network

### Setting the Blockchain ID in the Contracts

Make sure to replace the blockchainID in the sender contract `src/1-invoking-functions/CalculatorSenderOnCChain.sol` with the ID of your Subnet's blockchain.

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

### Sender Contract
```bash
forge create --rpc-url local-c --private-key $PK src/2a-invoking-functions/CalculatorSenderOnCChain.sol:SimpleCalculatorSenderOnCChain
```

Then save the sender contract address (displayed in `Deployed To:`) in an environment variable:

```bash
export SENDER_ADDRESS=0x123...
```
### Receiver Contract
```bash
forge create --rpc-url mysubnet --private-key $PK src/2a-invoking-functions/CalculatorReceiverOnSubnet.sol:SimpleCalculatorReceiverOnSubnet
```

Then save the sender contract address (displayed in `Deployed To:`) in an environment variable:

```bash
export RECEIVER_ADDRESS=0x123...
```

### Interaction

```bash 
cast send --rpc-url local-c --private-key $PK $SENDER_ADDRESS "sendAddMessage(address, uint256, uint256)" $RECEIVER_ADDRESS 2 3
```

## Verify Message Receipt

To check wether the message has been received, we can call the `result_num()` function on the sender contract. 

```bash
cast call --rpc-url mysubnet $RECEIVER_ADDRESS "result_num()(uint)"
```
