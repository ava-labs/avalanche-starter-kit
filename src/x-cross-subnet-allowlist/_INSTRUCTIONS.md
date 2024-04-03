
Teleporter Messenger successfully deployed to c-chain (0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
Teleporter Registry successfully deployed to c-chain (0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25)

Loading cli-teleporter-deployer key
Teleporter Messenger successfully deployed to mysubnet (0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf)
Teleporter Registry successfully deployed to mysubnet (0x74Cab8ec5A1e32b30548a91ECe67948572deeDad)


SENDER (CCHAIN): 
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0x8B3BC4270BE2abbB25BC04717830bd1Cc493a461
Transaction hash: 0x34b49bdc773faf6829cea79ca9077636568abac10ab7f7e7ea35e5e330143270

RECEIVER (ALLOWLIST):
Deployer: 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
Deployed to: 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25
Transaction hash: 0xb9fd16d1af9f35b5e4b57ce1d839f14a64537ba18a1fde51043a52a0be7a8816

#ADDRESSES: 
1) 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC
2) 0x88A50d56cF6ccA052213321FFd330bBB12fBa3d4

#Deploy SENDER
forge create --rpc-url local-c --private-key $PK  src/x-cross-subnet-allowlist/SenderOnCChain.sol:SenderOnCChain


#Deploy AllowList (Receiver)
forge create --rpc-url mysubnet --private-key $PK src/x-cross-subnet-allowlist/AllowListOnSubnet.sol:AllowListOnSubnet

# Send Sum message
cast send --rpc-url local-c --private-key $PK 0x8B3BC4270BE2abbB25BC04717830bd1Cc493a461 "sendAllowedSum(address,uint256,uint256)" 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25 5 2

# Add me as allowed address
cast send --rpc-url mysubnet --private-key $PK 0x17aB05351fC94a1a67Bf3f56DdbB941aE6c63E25 "allow(address)" 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC

cast call --rpc-url local-c 0x8B3BC4270BE2abbB25BC04717830bd1Cc493a461 "sum()(uint256)"