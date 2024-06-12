# Instructions - Send Roundtrip

The following code example will show you how to send a roundtrip message and verify the receival of messages using teleporter and foundry. It includes instructions for the [local network](#local-network).

## Local Network

### Setting the Blockchain ID in the Contracts

Make sure to replace the blockchainID in the sender contract `src/0-send-roundtrip/senderOnCChain.sol` with the ID of your Subnet's blockchain.

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
forge create --rpc-url local-c --private-key $PK src/1-send-roundtrip/senderOnCChain.sol:SenderOnCChain

```

```bash
forge create --rpc-url mysubnet --private-key $PK src/1-send-roundtrip/receiverOnSubnet.sol:ReceiverOnSubnet

```

### Sending a Message

You can find `<sender_contract_address>` in the output of the first and the `<receiver_contract_address>` of the second `forge create` command in the line saying `Deployed to:`.

```bash
cast send --rpc-url local-c --private-key $PK <sender_contract_address> "sendMessage(address)" <receiver_contract_address>
```

### Verifying Message Receipt

```bash
cast call --rpc-url local-c <sender_contract_address> "roundtripMessage()(string)"
```