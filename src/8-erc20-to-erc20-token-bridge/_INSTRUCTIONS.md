# Bridge an ERC20 Token to a Subnet as an ERC20 Token

The following example will show you how to send an ERC20 Token on C-chain to a Subnet as an ERC20 token using Teleporter and Foundry. This demo is conducted on a local network run by the CLI, but can be applied to Fuji Testnet and Avalanche Mainnet directly.

**All token bridge contracts and interfaces implemented in this example implementation are maintained in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/contracts/src) repository.**

If you prefer full end-to-end testing written in Golang for bridging ERC20s, native tokens, or any combination of the two, you can view the test workflows directly in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/tests/flows) repository.

Deep dives on each template interface can be found [here](https://github.com/ava-labs/teleporter-token-bridge/blob/main/contracts/README.md).

_Disclaimer: The teleporter-token-bridge contracts used in this tutorial are under active development and are not yet intended for production deployments. Use at your own risk._

## What we have to do

1. Create a Subnet and Deploy on Local Network
2. Deploy an ERC20 Contract on C-chain
3. Deploy the Bridge Contracts on C-chain and Subnet
4. Register Destination Bridge with Source Bridge
5. Approve Transaction
6. Start Sending Tokens

## Local Network Environment

For convenience the private key `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` of the default airdrop address is stored in the environment variable `$PK` in `.devcontainer/devcontainer.json`. Furthermore, the RPC url for the C-Chain `local-c` and Subnet created with the name `mysubnet` on the local network is set in the `foundry.toml` file.

### Subnet Configuration and Deployment

To get started, create a Subnet configuration named "mysubnet":

```bash
avalanche subnet create mysubnet
```

Your Subnet should have the following things:
- Teleporter enabled
- CLI should run an AWM Relayer
- Upon Subnet deployment, 100 tokens should be airdropped to the default ewoq address (0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC)
- Native Minter Precompile enabled with either your admin address or the pre-computed destination bridge address

_Note: If you have created your Subnet using AvaCloud, you can add destination bridge address [using the dashboard](https://support.avacloud.io/avacloud-how-do-i-use-the-native-token-minter)._

```bash
✔ Subnet-EVM
✔ Use latest release version
✔ Yes
✔ Yes
creating genesis for subnet mysubnet
Enter your subnet's ChainId. It can be any positive integer.
ChainId: 123
Select a symbol for your subnet's native token
Token symbol: TOK
✔ Low disk use    / Low Throughput    1.5 mil gas/s (C-Chain's setting)
✔ Customize your airdrop
Address to airdrop to: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Amount to airdrop (in ASH units): 100
✔ No
✔ Yes
✔ Native Minting
✔ Add
Enter Address : 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
✔ Done
✔ Done
✔ Done
✔ No
✓ Successfully created subnet configuration
```

Finally, deploy your Subnet:

```bash
avalanche subnet deploy mysubnet
```

```bash
? Choose a network for the operation:
✔ Local Network
Deploying [mysubnet] to Local Network
```

The CLI will output addresses and information that will be important for the rest of the tutorial:

```bash
Deploying Blockchain. Wait until network acknowledges...

Teleporter Messenger successfully deployed to c-chain (0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
Teleporter Registry successfully deployed to c-chain (0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25)

Teleporter Messenger successfully deployed to mysubnet (0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
Teleporter Registry successfully deployed to mysubnet (0x73b1dB7E9923c9d8fd643ff381e74dd9618EA1a5)

using awm-relayer version (v1.3.0)
Executing AWM-Relayer...

<lots of node information...>

Browser Extension connection details (any node URL from above works):
RPC URL:           http://127.0.0.1:9650/ext/bc/bFjwbbhaSCotYtdZTPDrQwZn8uVqRoL7YbZxCxXY94k7Qhf3E/rpc
Codespace RPC URL: https://humble-cod-j4prxq655qpcpw96-9650.app.github.dev/ext/bc/bFjwbbhaSCotYtdZTPDrQwZn8uVqRoL7YbZxCxXY94k7Qhf3E/rpc
Funded address:    0x834E891749c29d1417f4501B72945B72224d10dB with 600 (10^18)
Funded address:    0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC with 100 (10^18) - private key: 56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027
Network name:      mysubnet
Chain ID:          123
Currency Symbol:   TOK
```

From this output, take note of the following parameters
- Funded Address (with 100 tokens),
- Teleporter Registry on C-chain, and
- Teleporter Registry on Subnet

Set these parameters as environment variables so that we can manage them easily and also use them in the commands later.

```bash
export FUNDED_ADDRESS=<Funded Address (with 100 tokens)>
export TELEPORTER_REGISTRY_C_CHAIN=<Teleporter Registry on C-chain>
export TELEPORTER_REGISTRY_SUBNET=<Teleporter Registry on Subnet>
```

## Deploy ERC20 Contract on C-chain

First step is to deploy the ERC20 contract. We are using OZs example contract here and the contract is renamed to `ERC20.sol` for convenience. You can use any other pre deployed ERC20 contract or change the names according to your Subnet native token as well.

```bash
forge create --rpc-url local-c --private-key $PK src/8-erc20-to-erc20-token-bridge/ERC20.sol:TOK
```

Now, make sure to add the contract address in the environment variables. 
```bash
export ERC20_ORIGIN_C_CHAIN=<"Deployed to" address>
```

If you deployed the above example contract, you should see a balance of 100,000 tokens when you run the below command:

```bash
cast call --rpc-url local-c --private-key $PK $ERC20_ORIGIN_C_CHAIN "balanceOf(address)" $FUNDED_ADDRESS
```

## Deploy Bridge Contracts

We will deploy two bridge contracts. One of the source chain (which is C-chain in our case) and another on the destination chain (mysubnet in our case).

### ERC20Source Contract

```bash
forge create --rpc-url local-c --private-key $PK lib/teleporter-token-bridge/contracts/src/ERC20Source.sol:ERC20Source --constructor-args $TELEPORTER_REGISTRY_C_CHAIN $FUNDED_ADDRESS $ERC20_ORIGIN_C_CHAIN
```

Export the "Deployed to" address as an environment variables.
```bash
export ERC20_ORIGIN_BRIDGE_C_CHAIN=<"Deployed to" address>
```

### ERC20 Destination

To ensure the wrapped token is bridged into the destination chain (in this case, C-Chain) you'll need to deploy a _destination_ contract that implements the `IERC20Bridge` interface, as well as inheriting the properties of `TeleporterTokenDestination`. In order for the bridged tokens to have all the normal functionality of a locally deployed ERC20 token, this destination contract must also inherit the properties of a standard `ERC20` contract.

First, get the `Source Blockchain ID` in hexidecimal format, which in this example is the BlockchainID of your Subnet, run:

```zsh
avalanche subnet describe mysubnet
```

```bash
export SUBNET_BLOCKCHAIN_ID_HEX=0x4d569bf60a38e3ab3e92afd016fe37f7060d7d63c44e3378f42775bf82a7642d
```

`Source Blockchain ID` is in the field: `Local Network BlockchainID (HEX)`.

Do the same for the C-Chain:

```zsh
avalanche primary describe
```

`Destination Blockchain ID` is in the field: `BlockchainID (HEX)`.

```bash
export C_CHAIN_BLOCKCHAIN_ID_HEX=0x55e1fcfdde01f9f6d4c16fa2ed89ce65a8669120a86f321eef121891cab61241
```


Using the [`forge create`](https://book.getfoundry.sh/reference/forge/forge-create) command, we will deploy the [ERC20Destination.sol](./NativeTokenSource.sol) contract, passing in the following constructor arguments:



- Teleporter Registry Address **(for C-Chain)**
- Teleporter Manager (our funded address)
- Source Blockchain ID (hexidecimal representation of our Subnet's Blockchain ID)
- Token Source Address (address of NativeTokenSource.sol deployed on Subnet in the last step)
- Token Name (input in the constructor of the [wrapped token contract](./ExampleWNATV.sol))
- Token Symbol (input in the constructor of the [wrapped token contract](./ExampleWNATV.sol))
- Token Decimals (uint8 integer representing number of decimal places for the ERC20 token being created. Most ERC20 tokens follow the Ethereum standard, which defines 18 decimal places.)

```zsh
forge create --rpc-url mysubnet --private-key $PK lib/teleporter-token-bridge/contracts/src/ERC20Destination.sol:ERC20Destination \
--constructor-args "(${TELEPORTER_REGISTRY_SUBNET}, ${FUNDED_ADDRESS}, ${C_CHAIN_BLOCKCHAIN_ID_HEX}, ${ERC20_ORIGIN_BRIDGE_C_CHAIN})" "TOK" "TOK" 18
```

Note the address the source contract was "Deployed to".

export ERC20_TOKEN_DESTINATION_SUBNET=<"Deployed to" address>

## Register Destination Bridge with Source Bridge

After deploying the bridge contracts, you'll need to register the destination bridge by sending a dummy message using the `registerWithSource` method. This message includes details which inform the source bridge about your destination blockchain and bridge settings, eg. `initialReserveImbalance`.

```bash
cast send --rpc-url mysubnet --private-key $PK $ERC20_TOKEN_DESTINATION_SUBNET "registerWithSource((address, uint256))" "(0x0000000000000000000000000000000000000000, 0)"
```


### Approve tokens for the Source bridge contract

You can increase/decrease the numbers here as per your requirements. (All values are mentioned in wei)

```bash
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_C_CHAIN "approve(address, uint256)" $ERC20_ORIGIN_BRIDGE_C_CHAIN 2000000000000000000000
```

## Bridge the Token Cross-chain


Now that all the bridge contracts have been deployed, send a native token from your Subnet to C-Chain with the [`cast send`](https://book.getfoundry.sh/reference/cast/cast-send) foundry command.

`

```bash
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_BRIDGE_C_CHAIN "send((bytes32, address, address, address, uint256, uint256, uint256, address), uint256)" "(${SUBNET_BLOCKCHAIN_ID_HEX}, ${ERC20_TOKEN_DESTINATION_SUBNET}, ${FUNDED_ADDRESS}, ${ERC20_ORIGIN_C_CHAIN}, 0, 0, 250000, 0x0000000000000000000000000000000000000000)" 1000000000000000000000
```

## Check Balances

To confirm the token was bridged from C-Chain to a Subnet, we will check the recipient's balance of wrapped tokens on the Subnet with the [`cast call`](https://book.getfoundry.sh/reference/cast/cast-call?highlight=cast%20call#cast-call) foundry command:

```zsh
cast call --rpc-url mysubnet $ERC20_TOKEN_DESTINATION_SUBNET "balanceOf(address)(uint)" $FUNDED_ADDRESS
```
