# Bridge an ERC20 Token to a Subnet

The following code example will show you how to send an ERC20 Token to a Subnet using Teleporter and Foundry. This demo is conducted on a local network run by the CLI, but can be applied to Fuji Testnet and Avalanche Mainnet directly.

**All token bridge contracts and interfaces implemented in this example implementation are maintained in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/contracts/src) repository.**

If you prefer full end-to-end testing written in Golang for bridging ERC20s, native tokens, or any combination of the two, you can view the test workflows directly in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/tests/flows) repository.

Deep dives on each template interface can be found [here](https://github.com/ava-labs/teleporter-token-bridge/blob/main/contracts/README.md).

_Disclaimer: The teleporter-token-bridge contracts used in this tutorial are under active development and are not yet intended for production deployments. Use at your own risk._

## What we have to do

1. Deploy an ERC20 Contract on Fuji
2. Create a subnet

## Deploy ERC20 Contract on Fuji

Run the following command:
```
avalanche network start
```

Deploy the OpenZepillin ERC20 Contract
```
forge create --rpc-url local-c --private-key $PK src/6-erc20-to-native-token-bridge/ERC20.sol:MyToken
```

Set the contract address as an Environment Variable. 
```
export ERC20_ORIGIN_C_CHAIN=<"Deployed to" Contract Adress>
```



## Local Network Environment

For convenience the private key `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` of the default airdrop address is stored in the environment variable `$PK` in `.devcontainer/devcontainer.json`. Furthermore, the RPC url for the C-Chain `local-c` and any Subnet created with the name `mysubnet` on a local network is set in the `foundry.toml` file.

## Subnet Configuration

TODO Imbalanace customize airdrop

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

The CLI will output addresses and information that will be important for the rest of the tutorial:

```zsh
Deploying Blockchain. Wait until network acknowledges...

Teleporter Messenger successfully deployed to c-chain (0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
Teleporter Registry successfully deployed to c-chain (0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25)

Teleporter Messenger successfully deployed to mysubnet (0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
Teleporter Registry successfully deployed to mysubnet (0x004e6Bb21bc27E5F367EB278Be0ef39cDD1A77F6)

<lots of node information
...>

Browser Extension connection details (any node URL from above works):
RPC URL:           http://127.0.0.1:9650/ext/bc/G8ckkPsWkKdbXjDDU77wzL8sS4w67N2afG6MXKbDmvrQG5R7B/rpc
Codespace RPC URL: https://expert-space-fishstick-wqg5x974rpqc9wqp-9650.app.github.dev/ext/bc/G8ckkPsWkKdbXjDDU77wzL8sS4w67N2afG6MXKbDmvrQG5R7B/rpc
Funded address:    0x6c86eE2D6e789c44dE1a15669aEb87cE9A8a80E9 with 600
Funded address:    0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC with 1000000 (10^18) - private key: 56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027
Network name:      mysubnet
Chain ID:          797979
Currency Symbol:   NATV
```

From this output, take note of the following parameters
- Funded Address (with 1000000)
- Teleporter Registry (c-chain)
- Teleporter Registry (subnet)

and set Parameter as Environment Variables so we can manage them easily and also use them in the commands later.
```
export FUNDED_ADDRESS= <Set Funded Address (with 1000000)>
export TELEPORTER_REGISTRY_C_CHAIN= <Teleporter Registry (c-chain)>
export TELEPORTER_REGISTRY_SUBNET=<Teleporter Registry (subnet)>
```

## Deploy Bridge Contracts
### ERC20 Source Contract



```
forge create --rpc-url local-c --private-key $PK lib/teleporter-token-bridge/contracts/src/ERC20Source.sol:ERC20Source --constructor-args $TELEPORTER_REGISTRY_C_CHAIN $FUNDED_ADDRESS $ERC20_ORIGIN_C_CHAIN
```

Export the "Deployed to" address as an Environment Variables.
```
export ERC20_ORIGIN_BRIDGE_C_CHAIN=<"Deployed to" address>
```

### Native Token Destination

export C_CHAIN_BLOCKCHAIN_ID_HEX=0x55e1fcfdde01f9f6d4c16fa2ed89ce65a8669120a86f321eef121891cab61241



```
forge create --rpc-url mysubnet --private-key $PK lib/teleporter-token-bridge/contracts/src/NativeTokenDestination.sol:NativeTokenDestination --constructor-args "(NATV, ${TELEPORTER_REGISTRY_SUBNET}, ${FUNDED_ADDRESS}, ${C_CHAIN_BLOCKCHAIN_ID_HEX}, ${ERC20_ORIGIN_BRIDGE_C_CHAIN}, 10, 0, false, 0)"
```

string nativeAssetSymbol;
    address teleporterRegistryAddress;
    address teleporterManager;
    bytes32 sourceBlockchainID;
    address tokenSourceAddress;
    uint256 initialReserveImbalance;
    uint8 decimalsShift;
    bool multiplyOnDestination;
    uint256 burnedFeesReportingRewardPercentage;


NATIVE_TOKEN_DESTINATION_SUBNET=0xa4DfF80B4a1D748BF28BC4A271eD834689Ea3407

### Granting Native Miniting Rights to Native Token Destination
Native Minter Precomplite Adress = 0x0200000000000000000000000000000000000001

```
cast send --rpc-url mysubnet --private-key $PK 0x0200000000000000000000000000000000000001 "setEnabled(address)" $NATIVE_TOKEN_DESTINATION_SUBNET
```

### Register with Source

registerWithSource(TeleporterFeeInfo

TeleporterFeeInfo {
    address feeTokenAddress;
    uint256 amount;

```
cast send --rpc-url mysubnet --private-key $PK $NATIVE_TOKEN_DESTINATION_SUBNET "registerWithSource((address, uint256))" "(0x0000000000000000000000000000000000000000, 0)"
```

#### check if registered

cast call --rpc-url local-c --private-key $PK $ERC20_ORIGIN_BRIDGE_C_CHAIN "registeredDestination(bytes32, address)((bool,uint256,uint256,bool))" $SUBNET_BLOCKCHAIN_ID_HEX $NATIVE_TOKEN_DESTINATION_SUBNET

function registeredDestination(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress
    ) public view virtual returns (DestinationBridgeSettings memory) {
        return registeredDestinations[destinationBlockchainID][destinationBridgeAddress];
    }


#### Approve Transaction
```
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_C_CHAIN "approve(address,uint256)" $ERC20_ORIGIN_BRIDGE_C_CHAIN 10
```

cast call --rpc-url local-c --private-key $PK $ERC20_ORIGIN_C_CHAIN "allowance(address, address)(uint)" $FUNDED_ADDRESS $ERC20_ORIGIN_BRIDGE_C_CHAIN


### Add Collerteral

```
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_BRIDGE_C_CHAIN "addCollateral(bytes32,address,uint256)" $SUBNET_BLOCKCHAIN_ID_HEX $NATIVE_TOKEN_DESTINATION_SUBNET 10
```

function addCollateral(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount
    ) external {
        _addCollateral(destinationBlockchainID, destinationBridgeAddress, amount);
    }



### Send Tokens Cross Chain

struct SendTokensInput {
    bytes32 destinationBlockchainID;
    address destinationBridgeAddress;
    address recipient;
    address primaryFeeTokenAddress;
    uint256 primaryFee;
    uint256 secondaryFee;
    uint256 requiredGasLimit;
    address multiHopFallback;
}


```bash
cast send --rpc-url local-c --private-key $PK $ERC20_ORIGIN_BRIDGE_C_CHAIN "send((bytes32,address,address,address,uint256,uint256,uint256, address), uint)" "(${SUBNET_BLOCKCHAIN_ID_HEX}, ${NATIVE_TOKEN_DESTINATION_SUBNET}, ${FUNDED_ADDRESS}, ${ERC20_ORIGIN_C_CHAIN}, 0, 0, 10000, 0x0000000000000000000000000000000000000000)" 1
```



### Check if successful
```
cast balance --rpc-url mysubnet $FUNDED_ADDRESS
```