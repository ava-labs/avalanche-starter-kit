# Bridge an Native Token to a Subnet as Native Token

The following example will show you how to send a native Token on C-chain to a Subnet as a native token using Teleporter and Foundry. This demo is conducted on a local network run by the CLI, but can be applied to Fuji Testnet and Avalanche Mainnet directly.

**All token bridge contracts and interfaces implemented in this example implementation are maintained in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/contracts/src) repository.**

If you prefer full end-to-end testing written in Golang for bridging ERC20s, native tokens, or any combination of the two, you can view the test workflows directly in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/tests/flows) repository.

Deep dives on each template interface can be found [here](https://github.com/ava-labs/teleporter-token-bridge/blob/main/contracts/README.md).

_Disclaimer: The teleporter-token-bridge contracts used in this tutorial are under active development and are not yet intended for production deployments. Use at your own risk._

## What we have to do

1. Create a Subnet and Deploy on Local Network
2. Wrap Native Token on C-Chain
3. Deploy the Bridge Contracts on C-chain and Subnet
4. Granting Native Minting Rights to NativeTokenDestination
5. Register Destination Bridge with Source Bridge
6. Add Collateral and Start Sending Tokens
7. Check Balances

## Local Network Environment

For convenience the private key `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` of the default airdrop address is stored in the environment variable `$PK` in `.devcontainer/devcontainer.json`. Furthermore, the RPC url for the C-Chain `local-c` and Subnet created with the name `mysubnet` on the local network is set in the `foundry.toml` file.

## Create Subnet Configuration and Deployment

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
Token symbol: NATV
✔ Low disk use    / Low Throughput    1.5 mil gas/s (C-Chain's setting)
✔ Customize your airdrop
Address to airdrop to: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Amount to airdrop (in NATV units): 100
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
Currency Symbol:   NATV
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

## Deploy Bridge Contracts

### Wrapped Native Token

On your originsubnet, deploy a wrapped token contract for your native token. When we configured the Subnet earlier, we named the token `NATV`. This is reflected in line 19 of our [example wrapped token contract](./ExampleWNATV.sol).

```
forge create --rpc-url local-c --private-key $PK src/7-native-to-native-token-bridge/ExampleWNATV.sol:WNATV
```

```zsh
[⠊] Compiling...
[⠃] Compiling 7 files with Solc 0.8.18
[⠊] Solc 0.8.18 finished in 778.12ms
Compiler run successful!
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922
Transaction hash: 0x054e7b46b221c30f400b81df0fa2601668ae832054cf8e8b873f4ba615fa4115
```

Export the "Deployed to" address as an environment variables.
```bash
export WRAPPED_NATIVE_C_CHAIN=<"Deployed to" address>
```



### Native Token Source

To bridge the token out of your Subnet, you'll need to first deploy a _source_ contract on your Subnet that implements the `INativeTokenBridge` interface, and inherits the properties of the `TeleporterTokenSource` contract standard.

Using the [`forge create`](https://book.getfoundry.sh/reference/forge/forge-create) command, we will deploy the [NativeTokenSource.sol](./NativeTokenSource.sol) contract, passing in the following constructor arguments:

```zsh
forge create --rpc-url local-c --private-key $PK lib/teleporter-token-bridge/contracts/src/NativeTokenSource.sol:NativeTokenSource --constructor-args $TELEPORTER_REGISTRY_C_CHAIN $FUNDED_ADDRESS $WRAPPED_NATIVE_C_CHAIN
```

```

Export the "Deployed to" address as an environment variables.

```zsh
export NATIVE_ORIGIN_BRIDGE_C_CHAIN=<"Deployed to" address>
```

### NativeTokenDestination Contract

In order to deploy this contract, we'll need the source chain BlockchainID (in hex). For Local network, you can easily find the BlockchainID using the `avalanche primary describe` command. Make sure you add it in the environment variables.

It's also recommended that you set the BlockchainID for mysubnet in order to avoid any issues later. It can be found using the `avalanche subnet describe <subnet-name>` command.

Export the addresses as an environment variables.

```bash
export C_CHAIN_BLOCKCHAIN_ID_HEX=0x55e1fcfdde01f9f6d4c16fa2ed89ce65a8669120a86f321eef121891cab61241
export SUBNET_BLOCKCHAIN_ID_HEX=0x4dc739c081bee16a185b05db1476f7958f5a21b05513b6f9f0ae722dcc1e42f0
```

Now, deploy the bridge contract on mysubnet.

```bash
forge create --rpc-url mysubnet --private-key $PK lib/teleporter-token-bridge/contracts/src/NativeTokenDestination.sol:NativeTokenDestination --constructor-args "(${TELEPORTER_REGISTRY_SUBNET}, ${FUNDED_ADDRESS}, ${C_CHAIN_BLOCKCHAIN_ID_HEX}, ${NATIVE_ORIGIN_BRIDGE_C_CHAIN})" "NATV" 700000000000000000000 0 false 0
```

Export the "Deployed to" address as an environment variables.
```bash
export NATIVE_TOKEN_DESTINATION_SUBNET=<"Deployed to" address>
```

### Granting Native Minting Rights to NativeTokenDestination Contract

In order to mint native tokens on Subnet when received from the C-chain, the NativeTokenDestination contract must have minting rights. We pre-initialized the Native Minter Precompile with an admin address owned by us. We can use our rights to add this contract address as one of the enabled addresses in the precompile.

_Note: Native Minter Precompile Address = 0x0200000000000000000000000000000000000001_

Sending below transaction will add our destination bridge contract as one of the enabled addresses.
```bash
cast send --rpc-url mysubnet --private-key $PK 0x0200000000000000000000000000000000000001 "setEnabled(address)" $NATIVE_TOKEN_DESTINATION_SUBNET
```

## Register Destination Bridge with Source Bridge

After deploying the bridge contracts, you'll need to register the destination bridge by sending a dummy message using the `registerWithSource` method. This message includes details which inform the source bridge about your destination blockchain and bridge settings, eg. `initialReserveImbalance`.

```bash
cast send --rpc-url mysubnet --private-key $PK $NATIVE_TOKEN_DESTINATION_SUBNET "registerWithSource((address, uint256))" "(0x0000000000000000000000000000000000000000, 0)"
```

### Check if Destination Bridge is Registered with the Source Bridge

_Note: This command results in "execution reverted" error. Needs to be fixed._

```bash
cast call --rpc-url local-c --private-key $PK $NATIVE_ORIGIN_BRIDGE_C_CHAIN "registeredDestination(bytes32, address)((bool,uint256,uint256,bool))" $SUBNET_BLOCKCHAIN_ID_HEX $NATIVE_TOKEN_DESTINATION_SUBNET
```

## Add Collateral and Start Sending Tokens

If you followed the instructions correctly, you should have noticed that we minted a supply of 700 ASH tokens on our Subnet. This increases the total supply of ASH token and its wrapped counterparts. We first need to collateralize the bridge by sending an amount equivalent to `initialReserveImbalance` to the destination subnet from the C-chain. Note that this amount will not be minted on the mysubnet so we recommend sending exactly an amount equal to `initialReserveImbalance`.

So the course of action in this section would be:
- Call the `addCollateral` method on Source bridge contract and send 700 tokens to the destination bridge contract
- Send 1000 tokens to your address on the Subnet and check your new balance



### Add Collateral

Since we had an `initialReserveImbalance` of 700 ASH tokens on mysubnet, we'll send 700 tokens from our side via the bridge contract. (All values are mentioned in wei)

```bash
cast send --rpc-url local-c --private-key $PK $NATIVE_ORIGIN_BRIDGE_C_CHAIN "addCollateral(bytes32, address)" $SUBNET_BLOCKCHAIN_ID_HEX $NATIVE_TOKEN_DESTINATION_SUBNET --value 700000000000000000000
```

### Send Tokens Cross Chain

Now, send 1000 WASH tokens to the destination chain on your funded address. (All values are mentioned in wei)

```bash
cast send --rpc-url local-c --private-key $PK $NATIVE_ORIGIN_BRIDGE_C_CHAIN "send((bytes32, address, address, address, uint256, uint256, uint256, address))" "(${SUBNET_BLOCKCHAIN_ID_HEX}, ${NATIVE_TOKEN_DESTINATION_SUBNET}, ${FUNDED_ADDRESS}, 0x0000000000000000000000000000000000000000, 0, 0, 250000, 0x0000000000000000000000000000000000000000)" --value 1000000000000000000000
```


## Check Balances

Now is the time for truth. You will receive errors along the way if anything is incorrect. Make sure you fix them according to the guide above.

If you did everything as described, you'll see that on the destination subnet (mysubnet), you have increased balance now. If you put the new balance in https://eth-converter.com/, you'll see that the balance increased exactly by 1000 tokens. This balance is also in Wei and when you put this value in the converter, you'll get ~1088 tokens.

```bash
cast balance --rpc-url mysubnet $FUNDED_ADDRESS
```

You can also confirm whether the bridge is collateralized now by running the below command:

```bash
cast call --rpc-url mysubnet $NATIVE_TOKEN_DESTINATION_SUBNET "isCollateralized()(bool)"
```
