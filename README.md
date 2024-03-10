## Teleporter Starter Kit

# Set Up

```
avalanche subnet create mysubnet
```

```
avalanche subnet deploy
```

```
avalanche subnet describe mysubnet
```

Make sure to add the RPC Url to the `foundry.toml` file to interact with the Subnet

```
[rpc_endpoints]
c-chain = "http://localhost:9650/ext/bc/C/rpc"
my-subnet = "http://localhost:9650/ext/bc/BASE58_BLOCKCHAIN_ID/rpc"
```

Find the blockchainID of your Subnet

```
cast call --rpc-url mysubnet 0x0200000000000000000000000000000000000005 "getBlockchainID()(bytes32)" 
``` 


# Issuing Transactions with Foundry

For convenience the default airdrop private `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` is stored in the environment variable `$PK`. Furthermore, the RPC-url for the C-Chain is set in the `foundry.toml` file. 


## Deploying Contracts

Make sure to replace the blockchainID in the sender contract `src/0-send-receive/senderOnCChain.sol` with the ID of your Subnet's blockchain.

```
forge create --rpc-url c-chain --private-key $PK src/0-send-receive/senderOnCChain.sol:SenderOnCChain

```

```
forge create --rpc-url mysubnet --private-key $PK src/0-send-receive/receiverOnSubnet.sol:ReceiverOnSubnet

```

## Sending a Message

You can find `<sender_contract_address>` in the output of the first and the `<receiver_contract_address>` of the second `forge create` command.

```
cast send --rpc-url c-chain --private-key $PK <sender_contract_address> "sendMessage(address,string)" <receiver_contract_address> "Hello"
```

## Verifying Message Receipt
```
cast call --rpc-url mysubnet <receiver_contract_address> "lastMessage()(string)"
```
