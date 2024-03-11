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
local-c = "http://localhost:9650/ext/bc/C/rpc"
my-subnet = "http://localhost:9650/ext/bc/BASE58_BLOCKCHAIN_ID/rpc"
```

Find the blockchainID of your Subnet

```
cast call --rpc-url mysubnet 0x0200000000000000000000000000000000000005 "getBlockchainID()(bytes32)" 
``` 


# Issuing Transactions with Foundry

## Local Network

For convenience the private key `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` of the default airdrop address is stored in the environment variable `$PK`. Furthermore, the RPC-url for the C-Chain of your local network is set in the `foundry.toml` file. 

### Deploying Contracts

Make sure to replace the blockchainID in the sender contract `src/0-send-receive/senderOnCChain.sol` with the ID of your Subnet's blockchain.

```
forge create --rpc-url local-c --private-key $PK src/0-send-receive/senderOnCChain.sol:SenderOnCChain

```

```
forge create --rpc-url mysubnet --private-key $PK src/0-send-receive/receiverOnSubnet.sol:ReceiverOnSubnet

```

### Sending a Message

You can find `<sender_contract_address>` in the output of the first and the `<receiver_contract_address>` of the second `forge create` command.

```
cast send --rpc-url local-c --private-key $PK <sender_contract_address> "sendMessage(address,string)" <receiver_contract_address> "Hello"
```

### Verifying Message Receipt
```
cast call --rpc-url mysubnet <receiver_contract_address> "lastMessage()(string)"
```

## Fuji Testnet

### Creating a Wallet 

For deploying on testnet, we cannot use the airdrop wallet, since the private key is commonly known. To create a new wallet that is stored in a keystore, issue the following command. It will prompt you to secure the private key with a password.

```
cast wallet new .
```

You should now see a new Keystore in the root of your project looking something like this `c3832921-d2e6-4d9a-ba6f-017a37b12571`. Rename this file to `keystore`. For easier use of the keystore we already configured a envorinment variable called `KEYSTORE` pointing to the `keystore` file in the working directory.

You can use the wallet stored in the keystore by adding the `--keystore` flag instead of the `--private-key` flag.

```
cast wallet address --keystore $KEYSTORE
```

### Funding your Wallet with Fuji Tokens

Head to the [Avalanche Testnet Faucet](https://core.app/tools/testnet-faucet/?subnet=c&token=c) and fund your keystore address with Fuji AVAX and Dispatch tokens. Use the coupon code `avalanche-academy`.

### Deploying Contracts

```
forge create --rpc-url fuji-c --keystore $KEYSTORE src/0-send-receive/senderOnCChain.sol:SenderOnCChain
```

