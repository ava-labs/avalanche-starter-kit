admin = "0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC"
default source address (when deployed second): 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D
default destination address: 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922

Deploy ERC20 contract:
forge create --rpc-url local-c --private-key $PK src/erc20-to-native/mocks/ExampleWASH.sol:ExampleWASH

Deploy bridge contract on source:
forge create --rpc-url local-c --private-key $PK src/erc20-to-native/ERC20Source.sol:ERC20Source --constructor-args "0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25" "0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC" "0x5DB9A7629912EBF95876228C24A848de0bfB43A9"

Deploy bridge contract on destination: update teleporter subnet registry here
this command will specify the collateral to be 700 and the multiplier should be true
forge create --rpc-url mysubnet --private-key $PK src/erc20-to-native/NativeTokenDestination.sol:NativeTokenDestination --constructor-args "(0x73b1dB7E9923c9d8fd643ff381e74dd9618EA1a5, 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC, 0x55e1fcfdde01f9f6d4c16fa2ed89ce65a8669120a86f321eef121891cab61241, 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D)" "ASH" 700000000000000000000 18 true 0

default source address (when deployed second): 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D
default destination address: 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922

check collateralized: cast call --rpc-url mysubnet --private-key $PK 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "isCollateralized()(bool)"
check initial imbalance: cast call --rpc-url mysubnet --private-key $PK 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "initialReserveImbalance()(uint256)"


Mint 5000 tokens:
cast send --rpc-url local-c --private-key $PK 0x5DB9A7629912EBF95876228C24A848de0bfB43A9 "deposit()" --value 5000000000000000000000

check balance using this command: cast call --rpc-url local-c --private-key $PK 0x5DB9A7629912EBF95876228C24A848de0bfB43A9 "balanceOf(address)" 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
you have balance in your address by now. you can try and deposit some token to bridge contract: cast send --rpc-url local-c --private-key $PK 0x5DB9A7629912EBF95876228C24A848de0bfB43A9 "transferFrom(address,address,uint256)" 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D 200


APPROVE tokens to be spent by bridge contract on C-chain:
Now, APPROVE toke to be spent by the bridge contract: cast send --rpc-url local-c --private-key $PK 0x5DB9A7629912EBF95876228C24A848de0bfB43A9 "approve(address, uint256)" 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D 2000000000000000000000


register with source (add details here): cast send --rpc-url mysubnet --private-key $PK 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "registerWithSource((address, uint256))" "(0x0000000000000000000000000000000000000000,0)" 

Add Collateral (make sure to update destination blockchain ID):
cast send --rpc-url local-c --private-key $PK 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D "addCollateral(bytes32, address, uint256)" 0x108ce15038973062d8628fd20c8c657effe993dd8324297353e350dfc05dacad 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 700

Send the tokens:
now teleport the tokens: cast send --rpc-url local-c --private-key $PK 0x4Ac1d98D9cEF99EC6546dEd4Bd550b0b287aaD6D "send((bytes32, address, address, address, uint256, uint256, uint256, address), uint256)" "(0x5db6f3da2bbe7199427400cf4dad6fb1af47a1e184168b0f50930e3535f5f133, 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922, 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC, 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922, 0, 0, 250000, 0x0000000000000000000000000000000000000000)" 1000

check balance of ASH tokens: cast balance --rpc-url mysubnet 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC

Check if the bridge is collaterized:
collaterized check: cast call --rpc-url mysubnet 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "isCollateralized()(bool)"

On source side, make sure this increases: bridgedBalances
currentReserveImbalance should be decreasing after each teleporter message: cast call --rpc-url mysubnet 0x52C84043CD9c865236f11d9Fc9F56aa003c1f922 "currentReserveImbalance()(uint256)"