# Transfer an ERC20 Token to a Subnet as an ERC20 Token

The following example will show you how to send an ERC20 Token on C-chain to a Subnet as an ERC20 token using Teleporter and Foundry. This demo is conducted on a local network run by the CLI, but can be applied to Fuji Testnet and Avalanche Mainnet directly.

**All Avalanche Interchain Token Transfer contracts and interfaces implemented in this example implementation are maintained in the [avalanche-interchain-token-transfer](https://github.com/ava-labs/avalanche-interchain-token-transfer/tree/main/contracts/src) repository.**

If you prefer full end-to-end testing written in Golang for bridging ERC20s, native tokens, or any combination of the two, you can view the test workflows directly in the [avalanche-interchain-token-transfer](https://github.com/ava-labs/avalanche-interchain-token-transfer/tree/main/tests/flows) repository.

Deep dives on each template interface can be found [here](https://github.com/ava-labs/avalanche-interchain-token-transfer/blob/main/contracts/README.md).

_Disclaimer: The avalanche-interchain-token-transfer contracts used in this tutorial are under active development and are not yet intended for production deployments. Use at your own risk._

## What we have to do

1. Codespace Environment Setup
2. Create a Subnet and Deploy on Local Network
3. Deploy an ERC20 Contract on C-chain
4. Deploy the Avalanche Interchain Token Transfer Contracts on C-chain and Subnet
5. Start Sending Tokens

## Environment Setup

### Run on Github Codespace

You can run them directly on Github by clicking **Code**, switching to the **Codespaces** tab and clicking **Create codespace on main**. A new window will open that loads the codespace. Afterwards you will see a browser version of VS code with all the dependencies installed. Codespace time out after some time of inactivity, but can be restarted.

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

```bash
✔ Subnet-EVM
✔ Use latest release version
✔ Yes
✔ Yes
Installing subnet-evm-v0.6.6...
subnet-evm-v0.6.6 installation successful
creating genesis for subnet mysubnet
Enter your subnet's ChainId. It can be any positive integer.
ChainId: 123
Select a symbol for your subnet's native token
Token symbol: NAT
✔ Low disk use    / Low Throughput    1.5 mil gas/s (C-Chain's setting)
✔ Airdrop 1 million tokens to the default ewoq address (do not use in production)
prefunding address 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC with balance 1000000000000000000000000
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

using awm-relayer version (v1.3.3)
Installing AWM-Relayer v1.3.3
Executing AWM-Relayer...

<lots of node information...>

Browser Extension connection details (any node URL from above works):
RPC URL:           http://127.0.0.1:9650/ext/bc/2u9Hu7Noja3Z1kbZyrztTMZcDeqb6acwyPyqP4BbVDjoT8ZaYc/rpc
Codespace RPC URL: https://organic-palm-tree-ppr5xxg7xvv2974r-9650.app.github.dev/ext/bc/2u9Hu7Noja3Z1kbZyrztTMZcDeqb6acwyPyqP4BbVDjoT8ZaYc/rpc
Funded address:    0x69AD03393144008463beD1DcB3FD33eb9A7081ba with 600 (10^18)
Funded address:    0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC with 1000000 (10^18) - private key: 56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027
Network name:      mysubnet
Chain ID:          123
Currency Symbol:   NAT
```

From this output, take note of the Funded Address (with 100 tokens) and set the parameter as environment variable so that we can manage them easily and also use them in the commands later.

```bash
export FUNDED_ADDRESS=<Funded Address (with 100 tokens)>
```

## Deploy ERC20 Contract on C-chain

First step is to deploy the ERC20 contract. We are using OZs example contract here and the contract is renamed to `ERC20.sol` for convenience. You can use any other pre deployed ERC20 contract or change the names according to your Subnet native token as well.

```bash
forge create --rpc-url local-c --private-key $PK src/8-erc20-to-erc20-interchain-token-transfer/ERC20.sol:TOK
```

Now, make sure to add the contract address in the environment variables.

```bash
export ERC20_HOME_C_CHAIN=<"Deployed to" address>
```

If you deployed the above example contract, you should see a balance of 100,000 tokens when you run the below command:

```bash
cast call --rpc-url local-c --private-key $PK $ERC20_HOME_C_CHAIN "balanceOf(address)(uint)" $FUNDED_ADDRESS
```

## Deploy Avalanche Interchain Token Transfer Contracts

We will deploy two Interchain Token Transfer contracts. One of the source chain (which is C-chain in our case) and another on the destination chain (mysubnet in our case). This will be done by a single command with the Avalanche CLI

```bash
avalanche interchain tokenTransferrer deploy
```
Go

```bash
✔ Local Network
✔ C-Chain
✔ Deploy a new Home for the token
✔ An ERC-20 token
Enter the address of the ERC-20 Token: 0x5DB9A7629912EBF95876228C24A848de0bfB43A9
✔ Subnet mysubnet
Downloading Avalanche InterChain Token Transfer Contracts
Compiling Avalanche InterChain Token Transfer

Home Deployed to http://127.0.0.1:9650/ext/bc/C/rpc
Home Address: 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D

Remote Deployed to http://127.0.0.1:9650/ext/bc/2u9Hu7Noja3Z1kbZyrztTMZcDeqb6acwyPyqP4BbVDjoT8ZaYc/rpc
Remote Address: 0x0D189a705c1FFe77F1bF3ee834931b6b9B356c05
```

Save the Remote contract address in the environment variables.

```bash
export ERC20_REMOTE_SUBNET=<"Remote address">
```

## Get Balances

Before transfering some funds Cross-Chain, check the current balances of both the ERC20 Home token and the Remote one. 

```bash
avalanche key list --local --keys ewoq  --subnets c,mysubnet --tokens $ERC20_HOME_C_CHAIN,$ERC20_REMOTE_SUBNET
```

```bash
+--------+------+---------+--------------------------------------------+---------------+------------------+---------------+
|  KIND  | NAME | SUBNET  |                  ADDRESS                   |     TOKEN     |     BALANCE      |    NETWORK    |
+--------+------+---------+--------------------------------------------+---------------+------------------+---------------+
| stored | ewoq | mysubnet | 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC | TOK (0x0D18.)|               0  | Local Network |
+        +      +----------+--------------------------------------------+---------------+-----------------+---------------+
|        |      | C-Chain  | 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC | TOK (0x5DB9.)| 100000.000000000 | Local Network |
+--------+------+----------+--------------------------------------------+---------------+-----------------+---------------+
```

## Transfer the Token Cross-chain

Now that the Avalanche Interchain Token Transfer contracts have been deployed, transfer some ERC20 tokens TOK from C-Chain to _mysubnet_ with the following command

```bash
avalanche key transfer
```

```
✔ Local Network
✔ C-Chain
✔ Subnet mysubnet
Enter the address of the Token Transferrer on c-chain: 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D
Enter the address of the Token Transferrer on mysubnet: 0x0D189a705c1FFe77F1bF3ee834931b6b9B356c05
✔ ewoq
✔ Key
✔ ewoq
Amount to send (TOKEN units): 100
```

## Get New Balances

Before transfering some funds Cross-Chain, check the current balances of both the ERC20 Home token and the Remote one. 

```bash
avalanche key list --local --keys ewoq  --subnets c,mysubnet --tokens $ERC20_HOME_C_CHAIN,$ERC20_REMOTE_SUBNET
```

```bash
+--------+------+----------+--------------------------------------------+---------------+-----------------+---------------+
|  KIND  | NAME |  SUBNET  |                  ADDRESS                   |     TOKEN     |     BALANCE     |    NETWORK    |
+--------+------+----------+--------------------------------------------+---------------+-----------------+---------------+
| stored | ewoq | mysubnet | 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC | TOK (0x0D18.) |   100.000000000 | Local Network |
+        +      +----------+--------------------------------------------+---------------+-----------------+---------------+
|        |      | C-Chain  | 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC | TOK (0x5DB9.) | 99900.000000000 | Local Network |
+--------+------+----------+--------------------------------------------+---------------+-----------------+---------------+
```
