# Avalanche Starter Kit

This starter kit will get you started with developing solidity smart contract dApps on the C-Chain or on an Avalanche Subnet. It provides all tools to build cross-Subnet dApps using Teleporter. It includes:

- **Avalanche CLI**: Run a local Avalanche Network
- **Foundry**:
  - Forge: Compile and Deploy smart contracts to the local network, Fuji Testnet or Mainnet
  - Cast: Interact with these smart contracts
- **Teleporter**: All contracts you may want to interact with Teleporter
- **AWM Relayer**: The binary to run your own relayer
- **Examples**: Contracts showcasing how to achieve common patterns, such as sending simple messages, call functions of a contract on another blockchain and bridging assets. Please note that these example contracts have not been audited and are for educational purposes only

## Set Up

This starter kit utilizes a Dev Container specification. Dev Containers use containerization to create consistent and isolated development environments. All of the above mentioned components are pre-installed in that container. These containers can be run using GitHub Codespaces or locally using Docker and VS Code. You can switch back and forth between the two options.

### Run on Github Codespace

You can run them directly on Github by clicking **Code**, switching to the **Codespaces** tab and clicking **Create codespace on main**. A new window will open that loads the codespace. Afterwards you will see a browser version of VS code with all the dependencies installed. Codespace time out after some time of inactivity, but can be restarted.

### Run Dev Container locally with Docker

Alternatively, you can run them locally. You need [docker](https://www.docker.com/products/docker-desktop/) installed and [VS Code](https://code.visualstudio.com/) with the extensions [Dev Container extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers). Then clone the repository and open it in VS Code. VS Code will ask you if you want to reopen the project in a container.

## Starting a local Avalanche Network

To start a local Avalanche network with your own teleporter-enabled Subnet inside the container follow these commands. Your Avalanche network will be completely independent of the Avalanche Mainnet and Fuji Testnet. It will have its own Primary Network (C-Chain, X-Chain & P-Chain). You will not have access to services available on Fuji (such as Chainlink services or bridges). If you require these, go to the [Fuji Testnet](#fuji-testnet) section.

First let's create out Subnet configuration. Follow the dialog and if you don't have special requirements for precompiles just follow the suggested options. For the Airdrop of the native token select "Airdrop 1 million tokens to the default ewoq address (do not use in production)". Keep the name "mysubnet" to avoid additional configuration.

```
avalanche subnet create mysubnet
```

Now let's spin up the local Avalanche network and deploy our Subnet. This will also deploy the Teleporter messenger and the registry on our Subnet and the C-Chain.

```bash
avalanche subnet deploy mysubnet
```

Make sure to add the RPC Url to the `foundry.toml` file if you have chosen a different name than `mysubnet`. If you've used `mysubnet` the rpc is already configured.

```toml
[rpc_endpoints]
local-c = "http://localhost:9650/ext/bc/C/rpc"
mysubnet = "http://localhost:9650/ext/bc/mysubnet/rpc"
anothersubnet = "http://localhost:9650/ext/bc/BASE58_BLOCKCHAIN_ID/rpc"
```

## Issuing Transactions with Foundry

### Local Network

For convenience the private key `56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027` of the default airdrop address is stored in the environment variable `$PK`. Furthermore, the RPC-url for the C-Chain of your local network is set in the `foundry.toml` file.

#### Setting the Blockchain ID in the Contracts

Make sure to replace the blockchainID in the sender contract `src/0-send-receive/senderOnCChain.sol` with the ID of your Subnet's blockchain.

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

#### Deploying the Contracts

After adapting the contracts you can deploy them with `forge create`:

```bash
forge create --rpc-url local-c --private-key $PK src/0-send-receive/senderOnCChain.sol:SenderOnCChain

```

```bash
forge create --rpc-url mysubnet --private-key $PK src/0-send-receive/receiverOnSubnet.sol:ReceiverOnSubnet

```

#### Sending a Message

You can find `<sender_contract_address>` in the output of the first and the `<receiver_contract_address>` of the second `forge create` command in the line saying `Deployed to:`.

```bash
cast send --rpc-url local-c --private-key $PK <sender_contract_address> "sendMessage(address,string)" <receiver_contract_address> "Hello"
```

#### Verifying Message Receipt

```bash
cast call --rpc-url mysubnet <receiver_contract_address> "lastMessage()(string)"
```

### Fuji Testnet

#### Creating a Wallet

For deploying on testnet, we cannot use the airdrop wallet, since the private key is commonly known. To create a new wallet that is stored in a keystore, issue the following command. It will prompt you to secure the private key with a password.

```bash
cast wallet new .
```

You should now see a new Keystore in the root of your project looking something like this `c3832921-d2e6-4d9a-ba6f-017a37b12571`. Rename this file to `keystore`. For easier use of the keystore we already configured a envorinment variable called `KEYSTORE` pointing to the `keystore` file in the working directory.

You can use the wallet stored in the keystore by adding the `--keystore` flag instead of the `--private-key` flag.

```bash
cast wallet address --keystore $KEYSTORE
```

#### Funding your Wallet with Fuji Tokens

Head to the [Avalanche Testnet Faucet](https://core.app/tools/testnet-faucet/?subnet=c&token=c) and fund your keystore address with Fuji AVAX and Dispatch tokens. Use the coupon code `avalanche-academy`.

#### Setting the Blockchain ID in the Contracts on Fuji

Make sure to adapt the destinationBlockchainID of your sending contracts to use the blockchain IDs of the Fuji network:

| Chain | Blockchain ID |
|-------|---------------|
| Fuji C-Chain | 0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5 |
| Dispatch | 0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7 |

#### Deploying the Contracts

After adapting the contracts you can deploy them using your keystore wallet:

```bash
forge create --rpc-url fuji-c --keystore $KEYSTORE src/0-send-receive/senderOnCChain.sol:SenderOnCChain
```

```
forge create --rpc-url dispatch --keystore $KEYSTORE src/0-send-receive/receiverOnSubnet.sol:ReceiverOnSubnet

```

#### Sending a Message

```bash
cast send --rpc-url fuji-c --keystore $KEYSTORE <sender_contract_address> "sendMessage(address,string)" <receiver_contract_address> "Hello"
```

#### Verifying Message Receipt

```bash
cast call --rpc-url dispatch <receiver_contract_address> "lastMessage()(string)"
```
