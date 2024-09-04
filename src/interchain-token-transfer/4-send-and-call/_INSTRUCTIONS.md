# DexERC20Wrapper - Avalanche Interchain Token Transfer (ICTT) sendAndCall Instructions

This guide explains how to deploy and interact with the `DexERC20Wrapper` contract on the Avalanche network for interchain token transfers and swaps. It assumes that you have already deployed your source and destination tokens and that there is a Uniswap V2-like decentralized exchange on the destination chain.

> **Note:** The source and destination chains involved in this process are Avalanche Layer 1s (L1s), previously referred to as subnets. Developers have the flexibility to deploy their own Avalanche L1s and easily transfer tokens and execute logic between these L1s.

## Overview

The process involves the following steps:
1. **Deploy Source and Destination Tokens**: Deploy tokens on both the source and destination Avalanche L1 chains.
2. **Wrap Uniswap V2-like Contracts**: The `DexERC20Wrapper` contract is deployed on the destination chain to interact with the existing Uniswap V2-like contract.
3. **Trigger `sendAndCall`**: Use the `sendAndCall` function on the source chain to transfer tokens to the destination chain. The `DexERC20Wrapper` contract will be triggered on the destination chain, executing the swap logic.

## Prerequisites

- **Source and Destination Tokens**: Ensure that your tokens are deployed on both the source and destination Avalanche L1 chains.
- **Uniswap V2-like Contracts**: The destination chain should have a Uniswap V2-like decentralized exchange with liquidity for the tokens you want to swap.

## Deploying the DexERC20Wrapper Contract

1. **Deploy the `DexERC20Wrapper` Contract**

   Deploy the contract on the destination chain by providing the addresses for the wrapped native token (e.g., WAVAX) and the Uniswap V2 factory.

   ```solidity
   constructor(
       address wrappedNativeAddress,
       address dexFactoryAddress
   )
   ```

   Example deployment command:

   ```bash
   forge create --rpc-url <destination-network-rpc-url> --private-key <your-private-key> src/interchain-token-transfer/4-send-and-call/DexERC20Wrapper.sol:DexERC20Wrapper --constructor-args <wrapped-native-address> <uniswap-factory-address>
   ```

2. **Event Emissions**

   The contract emits the `TokensReceived` event when tokens are received from the source chain. This event helps in tracking the token transfers and swap execution.

   ```solidity
   event TokensReceived(
       bytes32 indexed sourceBlockchainID,
       address indexed originTokenTransferrerAddress,
       address indexed originSenderAddress,
       address token,
       uint256 amount,
       bytes payload
   );
   ```

## Using the Contract for Interchain Transfers

### Step 1: Triggering `sendAndCall`

On the source chain, trigger the `sendAndCall` function to initiate the token transfer. Once the tokens are successfully sent, the `DexERC20Wrapper` contract on the destination chain will automatically be triggered.

The `receiveTokens` function in the `DexERC20Wrapper` contract will handle the received tokens, query the swap price, check for slippage, and execute the swap if conditions are met.

### Step 2: Swap Logic Execution

Upon receiving the tokens, the contract performs the following actions:

1. **Query Swap Price**: The contract queries the swap price using the internal `query` function and ensures that the output amount meets the minimum specified in the `payload` (slippage protection).
2. **Execute Swap**: The swap is executed on the Uniswap V2-like contract. If the output token is a native token (e.g., AVAX), the contract unwraps it and transfers the native token to the original sender.
3. **Slippage Check**: Slippage is handled by checking that the output amount is greater than or equal to the `minAmountOut` specified in the payload.

### Step 3: Handling Native Tokens

If the output token is a native asset, such as AVAX, the contract unwraps it and sends it to the original sender:

```solidity
IWAVAX(WNATIVE).withdraw(amountOut);
payable(originSenderAddress).transfer(amountOut);
```

For ERC20 tokens, the contract transfers the swapped tokens directly to the sender's address.

## Conclusion

The `DexERC20Wrapper` contract allows for seamless interchain token transfers and swaps on Avalanche L1s. By following the steps outlined in this guide, you can deploy and interact with the contract to transfer and swap tokens across Avalanche L1 chains, with slippage protection and support for both native and ERC20 tokens.
