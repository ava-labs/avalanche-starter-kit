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


# Issuing Transactions with Foundry

For convenience the default airdrop private `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` is stored in the environment variable `$PK`. Furthermore, the RPC-url for the C-Chain is set in the `foundry.toml` file. 


## Sending Tokens
```
cast send --rpc-url c-chain --private-key $PK 0xF0f06058ca7B6e46E2B238F6d34A604DB1E2612f --value 1ether 
```

## Deploying Contracts
```
TBD
```

