# Build Your Own L1 Blockchain on Avalanche Fuji-CChain

This guide will help you build your own Avalanche Layer 1 (L1) blockchain network on the Avalanche Fuji C-Chain testnet.

## Contents
1. Requirements
2. Installing the Avalanche CLI
3. Installing AvalancheGo
4. Creating a Blockchain Configuration
5. Deploying Your L1 Network to Fuji Testnet
6. Installing AWM Relayer
7. Validator Setup
8. Adding Validators
9. Deploying Contracts for Cross-Chain Transactions
10. Bridging


## 1. Requirements

- Basic understanding of Solidity and TypeScript
- Familiarity with Avalanche Fuji Testnet
- Basic understanding of Linux and CLI
- Avalanche CLI and AvalancheGo

## 2. Installing the Avalanche CLI

To install the Avalanche CLI, open your terminal and download the latest release:

```bash
curl -sSfL https://raw.githubusercontent.com/ava-labs/avalanche-cli/main/scripts/install.sh | sh -s
```
Next, add the installed CLI to your PATH for easier access:

```bash
export PATH=~/bin:$PATH
source ~/.bashrc
```
To verify the installation, type:

```bash
[avalabs@ubuntu ~]$ avalanche -v
avalanche version 1.7.5
```
You should see the version information if the CLI was installed correctly.

## 3. Installing AvalancheGo

AvalancheGo is required to run validator nodes and interact with the subnet. Install AvalancheGo with the following command:

```bash
wget -nd -m https://raw.githubusercontent.com/ava-labs/avalanche-docs/master/scripts/avalanchego-installer.sh;\
chmod 755 avalanchego-installer.sh;\
./avalanchego-installer.sh

```
Once installed, start the AvalancheGo service:

```bash
[avalabs@ubuntu ~]$ sudo systemctl start avalanchego
```

Verify that AvalancheGo is running:

```bash 
[avalabs@ubuntu ~]$ sudo systemctl status avalanchego
```

Modify the ~/.avalanchego/configs/node.json file to work on Fuji testnet:

```bash
{
  "http-host": "",
  "public-ip-resolution-service": "opendns",
  "network-id": "fuji",
  "http-allowed-hosts": "*",
  "track-subnets": "[YOUR_SUBNET_ID]"
}
```


## 4. Creating a Blockchain Configuration
Create your blockchain using the Avalanche CLI:
```bash
[avalabs@ubuntu ~]$ avalanche blockchain create L1
```
I named my blockchain 'L1' and its native token 'USDC'. You can name it anything you want.

```
✔ Subnet-EVM
✔ I don't want to use default values
✔ Use latest release version
Chain ID: 1234
Token Symbol: USDC
✔ Define a custom allocation (Recommended for production)
✔ Add an address to the initial token allocation
Address to allocate to: 0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb
Amount to allocate (in USDC units): 100
✔ Confirm and finalize the initial token allocation
+--------------------------------------------+------------------------+
|                  ADDRESS                   |        BALANCE         |
+--------------------------------------------+------------------------+
| 0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb | 100.000000000000000000 |
+--------------------------------------------+------------------------+
✔ Yes
✔ Yes, I want to be able to mint additional the native tokens (Native Minter Precompile ON)
✔ Add an address for a role to the allow list
✔ Admin
✔ Enter the address of the account (or multiple comma separated): 0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb
✔ Confirm Allow List
+---------+--------------------------------------------+
| Admins  | 0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb |
+---------+--------------------------------------------+
| Manager |                                            |
+---------+--------------------------------------------+
| Enabled |                                            |
+---------+--------------------------------------------+

✔ Yes
✔ Medium block size / Medium Throughput 15 mil gas per block (C-Chain's setting)
✔ No, I prefer to have constant gas prices
✔ No, use the transaction fee configuration set in the genesis block
✔ Yes, I want the transaction fees to be burned
✔ Yes, I want to enable my blockchain to interoperate with other blockchains and the C-Chain
✔ Yes
creating genesis for blockchain L9
✓ Successfully created blockchain configuration

This will generate the configuration files for your blockchain.
```
Now my wallet (0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb) has 100 of the Native coin in L1.


### Setting up some wallets 
Let's first create the following two wallets (keys): one for Admin role and the other for the Relayer; we will get into more details later;

```bash
[avalabs@ubuntu ~]$ avalanche key create myRelayer
[avalabs@ubuntu ~]$ avalanche key create myAdmin
```
We use these two to manage our node later.

Check the list of keys:
```bash
[avalabs@ubuntu ~]$ avalanche key list
```
here are mine;
```
+--------+--------------+---------+-----------------------------------------------+-------+--------+
|  KIND  |    NAME      | SUBNET  |                    ADDRESS                    | TOKEN |BALANCE |
+--------+--------------+---------+-----------------------------------------------+-------+--------+
| stored |  myRelayer   | C-Chain | 0xbbA1CBb68645B7C63036ef1a5423331BE3654a0f    | AVAX  | 0.747  |
+        +              +---------+-----------------------------------------------+-------+--------+
|        |              | P-Chain | P-fuji1yuyvcxq685mjyq5e8pkwqakern2232u9n2xlpn | AVAX  |     0  |
+        +              +---------+-----------------------------------------------+-------+--------+
|        |              | X-Chain | X-fuji1yuyvcxq685mjyq5e8pkwqakern2232u9n2xlpn | AVAX  |     0  |
+--------+--------------+---------+-----------------------------------------------+-------+--------+
```

should be "Now, let's import the 'myAdmin' wallet into MetaMask.

```bash
[avalabs@ubuntu ~]$ avalanche key export myAdmin
[THE_WALLET_PRIMARY_KEY] will be outputted here.
```
Import the Private key into MetaMask; here is [how](https://support.metamask.io/managing-my-wallet/accounts-and-addresses/how-to-import-an-account/#:~:text=From%20the%20wallet%20view%2C%20tap,supported%20by%20the%20other%20wallet.).

Now head to the [Avalanche Testnet Faucet](https://core.app/tools/testnet-faucet/?subnet=c&token=c) and fund your Admin address with some Fuji AVAX and $USDC tokens. Use the coupon code `avalanche-academy`.


## 5. Deploying Your L1 Network to Fuji Testnet
```bash 
avalanche blockchain deploy L1 -f
? Which key source should be used to pay transaction fees?: 
  ▸ Use stored key
? Which stored key should be used to pay transaction fees?: 
  ▸ myAdmin (0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb)
? How would you like to set your control keys?: 
  ▸ Use fee-paying key
```

## 6. Installing AWM Relayer

```bash
[avalabs@ubuntu ~]$ avalanche teleporter relayer deploy
? In which Network will operate the Relayer?: 
  ▸ Fuji Testnet
? Which log level do you prefer for your relayer?: 
  ▸ info
? Do you want to add blockchain information to your relayer?: 
  ▸ Yes, I want to configure source and destination blockchains
? Configure the blockchains that will be interconnected by the relayer: 
  ▸ Add a blockchain
? What role should the blockchain have?: 
  ▸ Source and Destination
? Which blockchain do you want to set both as source and destination?: 
  ▸ C-Chain
? Which address do you want to receive relayer rewards on C-Chain?: 
    ▸ Get address from an existing stored key (created from avalanche key create or avalanche key import)
? Which stored key should be used to receive relayer rewards on C-Chain?: 
  ▸ myRelayer
Please provide a key that is not going to be used for any other purpose on destination
? Which private key do you want to use to pay relayer fees on C-Chain?: 
  ▸ Get private key from an existing stored key (created from avalanche key create or avalanche key import)
? Which stored key should be used to pay relayer fees on C-Chain?: 
  ▸ myRelayer
? Configure the blockchains that will be interconnected by the relayer: 
  ▸ Add a blockchain
? What role should the blockchain have?: 
  ▸ Source and Destination
? Which blockchain do you want to set both as source and destination?: 
  ▸ Blockchain L1
? Which address do you want to receive relayer rewards on L1?:
  ▸ Get address from an existing stored key (created from avalanche key create or avalanche key import)
? Which stored key should be used to receive relayer rewards on L1?: 
  ▸ myRelayer
Please provide a key that is not going to be used for any other purpose on destination
? Which private key do you want to use to pay relayer fees on L1?: 
✔ Get private key from an existing stored key (created from avalanche key create or avalanche key import)
? Which stored key should be used to pay relayer fees on L1?: 
  ▸ myRelayer
? Configure the blockchains that will be interconnected by the relayer: 
  ▸ Preview

+-------------+---------+
| Source      | C-Chain |
+             +---------+
|             | L1      |
+-------------+---------+
| Destination | C-Chain |
+             +---------+
|             | L1      |
+-------------+---------+
? Configure the blockchains that will be interconnected by the relayer: 
  ▸ Confirm
? Confirm?: 
  ▸ Yes
Relayer private key on destination C-Chain has a balance of 500
Relayer private key on destination L1 has a balance of 500

? Do you want to fund relayer destinations?: 
  ▸ Yes, I want to fund destination blockchains
? Do you want to fund relayer for destination C-Chain (balance=500)?: 
  ▸ Yes, I will send funds to it
? Which private key do you want to use to fund the relayer destination C-Chain?: 
  ▸ Get private key from an existing stored key (created from avalanche key create or avalanche key import)
? Which stored key should be used to fund the relayer destination C-Chain?: 
  ▸ myAdmin (already has NATIVE balance on both CChain and L1 )
✔ Amount to transfer: 1█
...
```
This command helps you deploy a Relayer to connect your blockchain with the CChain.

```bash 
teleporter relayer start

Executing Relayer
✓ Fuji Testnet AWM Relayer successfully started for Fuji Testnet Network
Logs can be found at /home/vscode/.avalanche-cli/runs/Fuji/local-relayer/awm-relayer.log
```

For documentation, you can refer to [this link](https://academy.avax.network/course/interchain-messaging/10-running-a-relayer/04-relayer-configuration).

## 7. Validator Setup

You need validators to secure your L1 blockchain network. Set up your validator on the Fuji testnet:

- Stake a minimum of 1 AVAX on the P-Chain
- Set your validator parameters such as node ID, BLS key, staking duration, and fee rate.

Use the following curl command to retrieve your node ID:

```bash 
curl -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' -H 'content-type:application/json;' 127.0.0.1:9650/ext/info
```
Follow the steps on the [Avalanche Docs](https://test.core.app/stake/validate/) to complete the staking process.

## 8. Adding Validators
To add validators, use the following command:

```bash 
avalanche blockchain addValidator L1

? Choose a network for the operation: 
  ▸ Fuji Testnet
? Which key source should be used to pay transaction fees?: 
  ▸ Use stored key
? Which stored key should be used to pay transaction fees?: 
  ▸ myAdmin [you ? by executing `avalanche key create MYKEY`]
Your subnet auth keys for add validator tx creation: [P-P-fuji17u0mdwwu5789le5j4dk23ecm8x75gr5uel82wl]
Next, we need the NodeID of the validator you want to whitelist.
#Check https://docs.avax.network/apis/avalanchego/apis/info#infogetnodeid for instructions about how to query the NodeID from your node
(Edit host IP address and port to match your deployment, if needed).
✔ What is the NodeID of the validator you'd like to whitelist?: NodeID-KhyfVpU6YgmDGzk5d9dLkf8k6dj2ZWRch

Your subnet auth keys for add validator tx creation: [P-P-fuji17u0mdwwu5789le5j4dk23ecm8x75gr5uel82wl]
Next, we need the NodeID of the validator you want to whitelist.


? What stake weight would you like to assign to the validator?: 
  ▸ Custom (choose 30)

When should your validator start validating?
If you validator is not ready by this time, subnet downtime can occur.
? Start time: 
  ▸ Start in 5 minutes 

? How long should your validator validate for?: 
  ▸ Until primary network validator expires

NodeID: NodeID-KhyfVpU6YgmDGzk5d9dLkf8k6dj2ZWRch
Network: Fuji
Start time: 2024-09-23 13:01:02
End time: 2024-10-22 17:36:28
Weight: 30
Inputs complete, issuing transaction to add the provided validator

```
You will need to provide the node ID of the validator and assign a stake weight.

## 9. Deploying Contracts for Cross-Chain Transactions

To enable ERC20 <-> Native cross-chain bridge, let deploy contracts for cross-chain transactions, we need two contracts:

- Token Home Contract: Manages tokens on the source chain (Avalanche Fuji).
- Token Remote Contract: Manages tokens on the destination chain (L1).
Use the forge create command to deploy the contracts. 

Let's start with the TokenHome, which we must deploy on Fuji-C-Chain:

This contract requires the `TeleporterRegistryAddress`, `TeleporterManager`, `TokenAddress`, and `TokenDecimals` as constructor arguments. 
We can use our admin address as the `TeleporterManager`.


Lets prepare our bash environment:
```bash
export FUNDED_ADDRESS=0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb #This is MyAdmin wallet address that we've added recently.

export TELEPORTER_REGISTERY_C_CHAIN=0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228 # it is already deployd by Avalabs: https://docs.avax.network/cross-chain/teleporter/deep-dive#deployed-addresses

export C_CHAIN_BLOCKCHAIN_ID_HEX=0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5

#  issue this command: avalanche blockchain describe L1 and find the `Teleporter Registry Address`
export TELEPORTER_REGISTERY_L1=0x56cB50BCeAbdaa9CF616bcD93F2d043AF809279a

export $PK = [THE_PRIMARY_KEY_OF_myAdmin_WALLET_ADDRESS]

# the ERC20 token of our interest: Circle $USDC
export TOKEN_USDC=0x5425890298aed601595a70AB815c96711a31Bc65
```

### Deploy HomeToken on C-Cahin:
```bash
forge create --rpc-url fuji-c --private-key $PK lib/avalanche-interchain-token-transfer/contracts/src/TokenHome/ERC20TokenHome.sol:ERC20TokenHome --constructor-args $TELEPORTER_REGISTERY_C_CHAIN $FUNDED_ADDRESS $TOKEN_USDC 6

[⠊] Compiling...
No files changed, compilation skipped
Deployer: 0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb
Deployed to: 0x6f268DC8547eC2B39C7e177ACD7EF1702865f9d8
Transaction hash: 0x9ef9f8151ec4a0d492bdfce3888fc169a1ef280f3772450836d084da3796eafe

```
After deploying, copy the 'Deployed to' address and add it to your environment variables
```bash
export TOKEN_HOME=0x6f268DC8547eC2B39C7e177ACD7EF1702865f9d8
```

### Deploy NativeRemoteToken on L1
```bash
forge create --rpc-url L1 --private-key $PK --revert-strings debug lib/avalanche-interchain-token-transfer/contracts/src/TokenRemote/NativeTokenRemote.sol:NativeTokenRemote --constructor-args "(${TELEPORTER_REGISTERY_L1}, ${FUNDED_ADDRESS}, ${C_CHAIN_BLOCKCHAIN_ID_HEX}, ${TOKEN_HOME}, 6)" "USDC" 1000000 0

[⠊] Compiling...
No files changed, compilation skipped
Deployer: 0xE2087BCC11F6518E5c6f06b1eEf97473E1d3B7Fb
Deployed to: 0x8706B00d0484a5b59ba0b3cCc593539B7671F287
Transaction hash: 0xace49b59d44a9267d1cf14e0ee6f157c0cccb9f50d7067739d080362b25bf09d
```
Remember that we set the <b>initialReserveImbalance</b> now is 1000000.


Copy the `Deployed to` address and add it to the environment:
```bash
export TOKEN_REMOTE=0x8706B00d0484a5b59ba0b3cCc593539B7671F287
```

### WHITELIST TOKEN REMOTE TO MINT on L1
We want to allow the TOKEN REMOTE to mint new Native coin on L1:
```bash
cast send --rpc-url L1 --private-key $PK  0x0200000000000000000000000000000000000001 "setEnabled(address)" $TOKEN_REMOTE
```

### Build the cross-chain connection

### Connect the REMOTE TOKEN (L1 NATIVE Coin) with the HOME TOKEN (Circle $USDC)
```bash
cast send --rpc-url L1 --private-key $PK  $TOKEN_REMOTE "registerWithHome((address, uint256))" "(0x0000000000000000000000000000000000000000, 0)"
```

### Validate the connection:
```bash
export L1_BLOCKCHAIN_ID=[YOUR_BLOCKCHAIN_ID] # get the value from: avalanche blockchain describe L1

cast call --rpc-url fuji-c --private-key $PK $TOKEN_HOME "registeredRemotes(bytes32,address)((bool,uint256,uint256,bool))" $L1_BLOCKCHAIN_ID $TOKEN_REMOTE
```
The result must be true.

If not, then check your relayer logs to make sure the relayer is fine:
```bash
avalanche teleporter relayer logs
```
you should see `Finished relaying message to destination chain`; if not, then reboot the relayer and try again:
```bash
avalanche teleporter relayer logs stop
avalanche teleporter relayer logs start
```

### finalize the connection

We need to collateralize the Token Home by sending an amount equivalent to the `initialReserveImbalance` to the destination subnet from the C-chain.

```bash
# APPROVE USDC
cast send --rpc-url fuji-c --private-key $PK  $TOKEN_USDC "approve(address, uint256)" $TOKEN_HOME 1000000

# Add Collatoral
cast send --rpc-url fuji-c --private-key $PK  $TOKEN_HOME "addCollateral(bytes32, address, uint256)" $L1_BLOCKCHAIN_ID $TOKEN_REMOTE 1000000
```

## 10. Bridging

### Bridge CChain ERC20 -> Native on L1

```bash

cast send --rpc-url fuji-c --private-key $PK  $TOKEN_USDC "approve(address, uint256)" $TOKEN_HOME [AMOUNT_TO_BRIDGE]

cast send --rpc-url fuji-c --private-key $PK $TOKEN_HOME "send((bytes32, address, address, address, uint256, uint256, uint256, address), uint256)" "(${L1_BLOCKCHAIN_ID}, ${TOKEN_REMOTE}, ${FUNDED_ADDRESS}, ${TOKEN_HOME}, 0, 0, 250000, 0x0000000000000000000000000000000000000000)" [AMOUNT_TO_BRIDGE]
```


### Bridge Native on L1 -> CChain ERC20
```bash
cast send --rpc-url L1 --private-key $PK $TOKEN_REMOTE "send((bytes32, address, address, address, uint256, uint256, uint256, address))" "(${C_CHAIN_BLOCKCHAIN_ID_HEX}, ${TOKEN_HOME}, $FUNDED_ADDRESS, 0x0000000000000000000000000000000000000000, 0, 0, 250000, 0x0000000000000000000000000000000000000000)" --value 1ether # or [AMOUNT_TO_BRIDGE]
```

Congratulations! You’ve successfully set up an Avalanche Layer 1 network for payments using USDC.