# Bridge an ERC20 Token &rarr; Subnet as Native Token

The following example will show you how to send an ERC20 Token on C-chain to a Subnet as a native token using Teleporter and Foundry. This demo is conducted on a local network run by the CLI, but can be applied to Fuji Testnet and Avalanche Mainnet directly.

**All token bridge contracts and interfaces implemented in this example implementation are maintained in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/contracts/src) repository.**

If you prefer full end-to-end testing written in Golang for bridging ERC20s, native tokens, or any combination of the two, you can view the test workflows directly in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/tests/flows) repository.

Deep dives on each template interface can be found [here](https://github.com/ava-labs/teleporter-token-bridge/blob/main/contracts/README.md).

_Disclaimer: The teleporter-token-bridge contracts used in this tutorial are under active development and are not yet intended for production deployments. Use at your own risk._

## What we have to do

1. Create a Subnet and Deploy on Local Network
2. Deploy an ERC20 Contract on C-chain
3. Deploy the Bridge Contracts on C-chain and Subnet
4. Register Destination Bridge with Source Bridge
5. Add Collateral and Start Sending Tokens

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
Token symbol: ASH
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
Currency Symbol:   ASH
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
forge create --rpc-url local-c --private-key $PK src/6-erc20-to-native-bridge/ERC20.sol:BOK
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

### NativeTokenDestination Contract

In order to deploy this contract, we'll need the source chain BlockchainID (in hex). For Local network, you can easily find the BlockchainID using the `avalanche primary describe` command. Make sure you add it in the environment variables.

It's also recommended that you set the BlockchainID for mysubnet in order to avoid any issues later. It can be found using the `avalanche subnet describe <subnet-name>` command.

```bash
export C_CHAIN_BLOCKCHAIN_ID_HEX=0x55e1fcfdde01f9f6d4c16fa2ed89ce65a8669120a86f321eef121891cab61241
export SUBNET_BLOCKCHAIN_ID_HEX=0x4dc739c081bee16a185b05db1476f7958f5a21b05513b6f9f0ae722dcc1e42f0
```

Now, deploy the bridge contract on mysubnet.

```bash
forge create --rpc-url mysubnet --private-key $PK lib/teleporter-token-bridge/contracts/src/NativeTokenDestination.sol:NativeTokenDestination --constructor-args "(${TELEPORTER_REGISTRY_SUBNET}, ${FUNDED_ADDRESS}, ${C_CHAIN_BLOCKCHAIN_ID_HEX}, ${ERC20_ORIGIN_BRIDGE_C_CHAIN})" "ASH" 700000000000000000000 0 false 0
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
cast call --rpc-url local-c --private-key $PK $ERC20_ORIGIN_BRIDGE_C_CHAIN "registeredDestination(bytes32, address)((bool,uint256,uint256,bool))" $SUBNET_BLOCKCHAIN_ID_HEX $NATIVE_TOKEN_DESTINATION_SUBNET
```

## Add Collateral and Start Sending Tokens

If you followed the instructions correctly, you should have noticed that we minted a supply of 700 ASH tokens on our Subnet. This increases the total supply of ASH token and its wrapped counterparts. We first need to collateralize the bridge by sending an amount equivalent to `initialReserveImbalance` to the destination subnet from the C-chain. Note that this amount will not be minted on the mysubnet so we recommend sending exactly an amount equal to `initialReserveImbalance`.

So the course of action in this section would be:
- Approve 2000 tokens for the Source bridge contract to use them
- Call the `addCollateral` method on Source bridge contract and send 700 tokens to the destination bridge contract
- Send 1000 tokens to your address on the Subnet and check your new balance

### Approve tokens for the Source bridge contract

You can increase/decrease the numbers here as per your requirements. (All values are mentioned in wei)

```bash
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_C_CHAIN "approve(address, uint256)" $ERC20_ORIGIN_BRIDGE_C_CHAIN 2000000000000000000000
```

### Add Collateral

Since we had an `initialReserveImbalance` of 700 ASH tokens on mysubnet, we'll send 700 tokens from our side via the bridge contract. (All values are mentioned in wei)

```bash
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_BRIDGE_C_CHAIN "addCollateral(bytes32, address, uint256)" $SUBNET_BLOCKCHAIN_ID_HEX $NATIVE_TOKEN_DESTINATION_SUBNET 700000000000000000000
```

### Send Tokens Cross Chain

Now, send 1000 WASH tokens to the destination chain on your funded address. (All values are mentioned in wei)

```bash
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_BRIDGE_C_CHAIN "send((bytes32, address, address, address, uint256, uint256, uint256, address), uint256)" "(${SUBNET_BLOCKCHAIN_ID_HEX}, ${NATIVE_TOKEN_DESTINATION_SUBNET}, ${FUNDED_ADDRESS}, ${ERC20_ORIGIN_C_CHAIN}, 0, 0, 250000, 0x0000000000000000000000000000000000000000)" 1000000000000000000000
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