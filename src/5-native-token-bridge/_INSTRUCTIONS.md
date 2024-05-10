# Bridge a Subnet's Native Token to the C-Chain

The following code example will show you how to send a Subnet's native token and to the C-Chain using Teleporter and Foundry. This demo is conducted on a local network run by the CLI, but can be applied to Fuji Testnet and Avalanche Mainnet directly.

If you prefer full end-to-end testing written in Goland for bridging ERC20s, Native tokens, or any combination of the two, you can view the test workflows directly in the [teleporter-token-bridge](https://github.com/ava-labs/teleporter-token-bridge/tree/main/tests/flows) repository.

Deep dives on each template interface can be found [here](https://github.com/ava-labs/teleporter-token-bridge/blob/main/contracts/README.md).

_Disclaimer: The teleporter-token-bridge contracts used in this tutorial are under active development and are not yet intended for production deployments. Use on Mainnet at your own risk._

## Local Network Environment

For convenience the private key `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` of the default airdrop address is stored in the environment variable `$PK` in `.devcontainer/devcontainer.json`. Furthermore, the RPC url for the C-Chain and any Subnet created with the name `mysubnet` on a local network is set in the `foundry.toml` file.

### Useful Commands

This tutorial uses the Avalanche-CLI. Some useful commands you can utilize to get information about your local network and subnet during testing are:

- `avalanche primary describe`: prints details of the primary network configuration, including `blockchainID` to the console
- `avalanche subnet describe <subnetName>`: prints details of the subnet configuration, including `blockchainID` to the console
- `avalanche key list --local --subnet mysubnet`: prints information for all stored signing keys, including native token balances

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

Make sure to make note of the following parameters, **which will vary with each Subnet deployment**:

| Parameter                      | Value                                      |
| :----------------------------- | :----------------------------------------- |
| Funded Address (with 1000000)  | 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC |
| Teleporter Registry (c-chain)  | 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25 |
| Teleporter Registry (mysubnet) | 0x004e6Bb21bc27E5F367EB278Be0ef39cDD1A77F6 |

## Parameter Management

As you deploy the teleporter contracts, keeping track of their addresses will make testing and troubleshooting much easier. The parameters you should keep track of include:

| Parameter                      | Network | Description                                                                                                                                         |
| :----------------------------- | :------ | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| Funded Address (with 1000000)  | Both    | The address you use to deploy contracts, and send tokens through the bridge. Used as the `teleporterManager` constructor parameter in this example. |
| Teleporter Registry            | C-Chain | Address of the TeleporterRegistry contract on C-Chain deployed by the CLI                                                                           |
| Teleporter Registry            | Subnet  | Address of the TeleporterRegistry contract on Subnet deployed by the CLI                                                                            |
| Wrapped Token Contract Address | Subnet  | Address of the TeleporterRegistry contract on Subnet deployed by the CLI                                                                            |

## Deploy Bridge Contracts

On your Subnet, deploy a wrapped token contract for your native token. When we configured the Subnet earlier, we named the token `NATV`. This is reflected in line 19 of our [example wrapped token contract](src/5-native-token-bridge/ExampleWNATV.sol).

```
forge create --rpc-url mysubnet --private-key $PK src/5-native-token-bridge/ExampleWNATV.sol:WNATV
```

Note the address the contract was "Deployed to". If anything about the contract is changed, **this address will be unique**:

```zsh
[⠊] Compiling...
[⠃] Compiling 7 files with Solc 0.8.18
[⠊] Solc 0.8.18 finished in 778.12ms
Compiler run successful!
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922
Transaction hash: 0x054e7b46b221c30f400b81df0fa2601668ae832054cf8e8b873f4ba615fa4115
```

Next

```
forge create --rpc-url mysubnet --private-key $PK src/5-native-token-bridge/NativeTokenSource.sol:NativeTokenSource --constructor-args <Registry>0xAd00Ce990172Cfed987B0cECd3eF58221471a0a3
<Manager>0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
<WrappedTokenAddress>0x52C84043CD9c865236f11d9Fc9F56aa003c1f922
```

```
forge create --rpc-url mysubnet --private-key $PK src/5-native-token-bridge/NativeTokenSource.sol:NativeTokenSource --constructor-args 0xAd00Ce990172Cfed987B0cECd3eF58221471a0a3 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922
```

```
forge create --rpc-url local-c --private-key $PK src/5-native-token-bridge/ERC20Destination.sol:ERC20Destination --constructor-args
<Registry>0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25 <Manager>0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC <SourceBlockchainID(HEX)>0x9c95f1209fd476ce703f698b2d6e657a63815d9963e50adedb7a5150a33bec4f
<tokenSourceAddress> 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25
<tokenName> "Wrapped NATV"
<tokenSymbol>"WNATV"
<decimals>18
```

```
forge create --rpc-url local-c --private-key $PK src/5-native-token-bridge/ERC20Destination.sol:ERC20Destination --constructor-args 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC 0xbcb8143686b1f0c765a1404bb94ad13134cafa5cf56f181a3a990ba21b1151b9 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25 "Wrapped NATV" "WNATV" 18
```

TeleporterRegistry: 0xAd00Ce990172Cfed987B0cECd3eF58221471a0a3
Funded Address(manager): 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC

“Deployed to”
WNATV(mysubnet): 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922
NativeTokenSource(mysubnet): 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25
ERC20Destination(c-chain):
