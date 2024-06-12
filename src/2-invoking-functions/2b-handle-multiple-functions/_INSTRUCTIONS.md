TO-DO

# Deploy Sender on C-chain
forge create --rpc-url local-c --private-key $PK src/2-invoking-functions/2b-handle-multiple-functions/CalculatorSenderOnCChain.sol:CalculatorSenderOnCChain


# Deploy Receiver on Subnet
forge create --rpc-url mysubnet --private-key $PK src/2-invoking-functions/2b-handle-multiple-functions/CalculatorReceiverOnSubnet.sol:CalculatorReceiverOnSubnet
