# Interchain Connection between Fuji C-Chain and MaGGA L1 Chain

Important variables:

```

MaGGA_BLOCKCHAIN_ID = 0x02f8b60b4d4070cf62e67802fe6532d4fcfc6582b4048d040ed6cfc7247d86d8
MaGGA_RPC = "https://subnets.avax.network/gaming/testnet/rpc"

FUJI_C_BLOCKCHAIN_ID = 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
FUJI_RPC = "https://api.avax-test.network/ext/bc/C/rpc"

```

# Create simple interchain messaging between Fuji C-Chain and MaGGA L1 Chain

1. Set up privat the privat key of your crypto wallet and save it as an environmental variable:

```
export PK=YOUR_PRIVATE_KEY
```


2. Deploy Sender Contract on C chain

```
forge create --rpc-url fuji-c --private-key $PK contracts/MaGGA/senderMaGGA.sol:SenderOnCChain
```


The output should look like this:

```
[⠊] Compiling...
[⠢] Compiling 2 files with Solc 0.8.18
[⠆] Solc 0.8.18 finished in 158.51ms
Compiler run successful!
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0xAAASENDER_CONTRACT_ADDRESS888
Transaction hash: 0x48a1ffaa8aa8011f842147a908ff35a1ebfb75a5a07eb37ae96a4cc8d7feafd7
```

3. If you are using Avacloud, authorize the Sender Contract on your L1 Blockchain.

4. Save the adress where the smart constract was deployed to:

```
export SENDER_CONTRACT_ADDRESS=0xAAASENDER_CONTRACT_ADDRESS888
```


5. Deploy Receiver Contract on MaGGA chain:

```
forge create --rpc-url MaGGA --private-key $PK contracts/MaGGA/receiverMaGGA.sol:ReceiverOnSubnet
```

The output should look like this:

```
[⠊] Compiling...
[⠒] Compiling 2 files with Solc 0.8.18
[⠢] Solc 0.8.18 finished in 81.53ms
Compiler run successful!
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0xYYYRECEIVER_CONTRACT_ADDRESS444
Transaction hash: 0xcde7873e9e3c68fb00a2ad6644dceb64a01a41941da46de5a0f559d6d70a1638
```

6. If you are using Avacloud, authorize the Sender Contract on your L1 Blockchain.

7. Save the adress where the smart constract was deployed to, executing the :

```
export RECEIVER_CONTRACT_ADDRESS=0xYYYRECEIVER_CONTRACT_ADDRESS444
```

8. Send Transaction from C-Chain to MaGGA L1 Chain:

```
cast send --rpc-url MaGGA --private-key $PK $SENDER_CONTRACT_ADDRESS "sendMessage(address,string)" $RECEIVER_CONTRACT_ADDRESS "Hello MaGGA!"
```

9. Read variable on MaGGA L1 Chain to make sure, that the right message was received:

```
cast call --rpc-url MaGGA $RECEIVER_CONTRACT_ADDRESS "lastMessage()(string)"
```


# Create simple token creation in MaGGA L1 Chain depending on a message from the Fuji C-Chain

1. If you do not have already set up a privat key, please refer to Step 1 of "Create simple interchain messaging between Fuji C-Chain and MaGGA L1 Chain":

```
export PK=YOUR_PRIVATE_KEY
```


2. Deploy the token creation contract on Fuji C-chain:

```
forge create --rpc-url fuji-c --private-key $PK contracts/MaGGA/createToken.sol:MyToken
```


The output should look like this:

```
[⠊] Compiling...
[⠢] Compiling 2 files with Solc 0.8.18
[⠆] Solc 0.8.18 finished in 158.51ms
Compiler run successful!
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0xAAATOKEN_CREATION_CONTRACT_ADDRESS888
Transaction hash: 0x48a1ffaa8aa8011f842147a908ff35a1ebfb75a5a07eb37ae96a4cc8d7feafd7
```

3. If you are using Avacloud, authorize the token creation smart contract (i.e. 0xAAATOKEN_CREATION_CONTRACT_ADDRESS888) on your L1 Blockchain.

4. Save the adress where the token creation smart contract was deployed to as an environmental variable:

```
export TOKEN_CREATION_CONTRACT_ADDRESS=0xAAATOKEN_CREATION_CONTRACT_ADDRESS888
```

5. Deploy Sender Contract on C chain

```
forge create --rpc-url fuji-c --private-key $PK contracts/MaGGA/sendAmount.sol:SendAmountOnCChain
```


The output should look like this:

```
[⠊] Compiling...
[⠢] Compiling 2 files with Solc 0.8.18
[⠆] Solc 0.8.18 finished in 158.51ms
Compiler run successful!
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0xAAASENDER_CONTRACT_ADDRESS888
Transaction hash: 0x48a1ffaa8aa8011f842147a908ff35a1ebfb75a5a07eb37ae96a4cc8d7feafd7
```

6. If you are using Avacloud, authorize the sender smart contract (i.e. 0xAAASENDER_CONTRACT_ADDRESS888) on your L1 Blockchain.

7. Save the adress where the sender smart contract was deployed to as an environmental variable:

```
export SENDER_CONTRACT_ADDRESS=0xAAASENDER_CONTRACT_ADDRESS888
```

8. Deploy Receiver Contract on MaGGA chain:

```
forge create --rpc-url MaGGA --private-key $PK contracts/MaGGA/receiveMaGGATokens.sol:ReceiveMaGGATokens
```

The output should look like this:

```
[⠊] Compiling...
[⠒] Compiling 2 files with Solc 0.8.18
[⠢] Solc 0.8.18 finished in 81.53ms
Compiler run successful!
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0xYYYRECEIVER_CONTRACT_ADDRESS444
Transaction hash: 0xcde7873e9e3c68fb00a2ad6644dceb64a01a41941da46de5a0f559d6d70a1638
```

9. If you are using Avacloud, authorize the Receiver Contract (i.e. 0xYYYRECEIVER_CONTRACT_ADDRESS444) on your L1 Blockchain.

10. Save the adress where the receiver smart constract was deployed to as an environmental varaible:

```
export RECEIVER_CONTRACT_ADDRESS=0xYYYRECEIVER_CONTRACT_ADDRESS444
```

11. Send Transaction from C-Chain to MaGGA L1 Chain:

```
cast send --rpc-url MaGGA --private-key $PK $SENDER_CONTRACT_ADDRESS "sendAmount(address,uint)" $RECEIVER_CONTRACT_ADDRESS 100
```

12. Read variable on MaGGA L1 Chain to make sure, that the right message was received:

```
cast call --rpc-url MaGGA $RECEIVER_CONTRACT_ADDRESS "lastAmount()(uint)"
```



# Avalanche Starter Kit

This starter kit will get you started with developing solidity smart contract dApps on the C-Chain or on an Avalanche L1. It provides all tools to build cross-L1 dApps using Teleporter. It includes:

- **Avalanche CLI**: Run a local Avalanche Network
- **Foundry**:
  - Forge: Compile and Deploy smart contracts to the local network, Fuji Testnet or Mainnet
  - Cast: Interact with these smart contracts
- **Teleporter**: All contracts you may want to interact with Teleporter
- **AWM Relayer**: The binary to run your own relayer
- **Examples**: Contracts showcasing how to achieve common patterns, such as sending simple messages, call functions of a contract on another blockchain and bridging assets. Please note that these example contracts have not been audited and are for educational purposes only
- **BuilderKit**: A component library providing UI elements for ICTT bridges, Cross-Chain swaps, ...

## Set Up

This starter kit utilizes a Dev Container specification. Dev Containers use containerization to create consistent and isolated development environments. All of the above mentioned components are pre-installed in that container. These containers can be run using GitHub Codespaces or locally using Docker and VS Code. You can switch back and forth between the two options.

### Run on Github Codespace

You can run them directly on Github by clicking **Code**, switching to the **Codespaces** tab and clicking **Create codespace on main**. A new window will open that loads the codespace. Afterwards you will see a browser version of VS code with all the dependencies installed. Codespace time out after some time of inactivity, but can be restarted.

### Run Dev Container locally with Docker

Alternatively, you can run them locally. You need [docker](https://www.docker.com/products/docker-desktop/) installed and [VS Code](https://code.visualstudio.com/) with the extensions [Dev Container extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers). Then clone the repository and open it in VS Code. VS Code will ask you if you want to reopen the project in a container.

## Starting a local Avalanche Network

To start a local Avalanche network with your own teleporter-enabled L1 inside the container follow these commands. Your Avalanche network will be completely independent of the Avalanche Mainnet and Fuji Testnet. It will have its own Primary Network (C-Chain, X-Chain & P-Chain). You will not have access to services available on Fuji (such as Chainlink services or bridges). If you require these, go to the [Fuji Testnet](#fuji-testnet) section.

First let's create out L1 configuration. Follow the dialog and if you don't have special requirements for precompiles just follow the suggested options. For the Airdrop of the native token select "Airdrop 1 million tokens to the default ewoq address (do not use in production)". Keep the name "mysubnet" to avoid additional configuration.

```
avalanche blockchain create myblockchain
```

Now let's spin up the local Avalanche network and deploy our L1. This will also deploy the Teleporter messenger and the registry on our L1 and the C-Chain.

```bash
avalanche blockchain deploy myblockchain
```

Make sure to add the RPC Url to the `foundry.toml` file if you have chosen a different name than `myblockchain`. If you've used `myblockchain` the rpc is already configured.

```toml
[rpc_endpoints]
local-c = "http://localhost:9650/ext/bc/C/rpc"
myblockchain = "http://localhost:9650/ext/bc/myblockchain/rpc"
anotherblockchain = "http://localhost:9650/ext/bc/BASE58_BLOCKCHAIN_ID/rpc"
```

## Code Examples

### Interchain Messaging
- [send-receive](https://academy.avax.network/course/interchain-messaging/04-icm-basics/01-icm-basics) 
- [send-roundtrip](https://academy.avax.network/course/interchain-messaging/05-two-way-communication/01-two-way-communication)
- [invoking-functions](https://academy.avax.network/course/interchain-messaging/06-invoking-functions/01-invoking-functions)
- [registry](https://academy.avax.network/course/interchain-messaging/07-icm-registry/01-icm-registry)
- [incentivized-relayer](https://academy.avax.network/course/interchain-messaging/12-incentivizing-a-relayer/01-incentivizing-a-relayer)

### Interchain Token Transfer
- [erc20-to-erc20](https://academy.avax.network/course/interchain-token-transfer/06-erc-20-to-erc-20-bridge/01-erc-20-to-erc-20-bridge) 
- [native-to-erc20](https://academy.avax.network/course/interchain-token-transfer/08-native-to-erc-20-bridge/01-native-to-erc-20-bridge)
- [native-to-native](https://academy.avax.network/course/l1-tokenomics/03-multi-chain-ecosystems/04-use-any-native-as-native-token)
- [erc20-to-native](https://academy.avax.network/course/l1-tokenomics/03-multi-chain-ecosystems/03-use-erc20-as-native-token)
- [cross-chain-token-swaps](https://academy.avax.network/course/interchain-token-transfer/13-cross-chain-token-swaps/07-exchange-contract)

### Misc
- [creating-contracts](contracts/misc/creating-contracts/REAEDME.md)
- [erc721-bridge](contracts/misc/erc721-bridge/README.md)


## Web-Apps
- [AvaCloud APIs](https://academy.avax.network/course/avacloudapis)
