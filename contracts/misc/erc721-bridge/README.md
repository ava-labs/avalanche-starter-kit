# Generic ERC721 Token Bridge

An ERC721 token bridge contract built on top of Teleporter to support bridging any ERC721 tokens between any `subnet-evm` instance.

## Design
The generic ERC721 bridge is implemented using two primary contracts.
- `BridgeNFT`
    - A simple extension of OpenZeppelin's `ERC721` contract.
    - Representation of an ERC721 token from another chain.
    - Identifies the specific native ERC721 contract and bridge it represents.
    - Automatically deployed by `ERC721Bridge` when new tokens are added to be supported by a bridge instance.
- `ERC721Bridge`
    - Bridge contract that uses Teleporter to facilitate the bridging operations of adding new supported tokens and moving tokens between chains.
    - Supports bridging of simple ERC721 tokens between any `subnet-evm` instance. Note: Some custom ERC721 implementations may include custom logic for minting, metadata(such as variants, rarity, etc.), and/or other features. This bridge implementation does not support bridging of these custom features.
    - Primary functions include:
        - `submitCreateBridgeNFT`: Called on the origin chain to add support for an ERC721 on a different chain's bridge instance. Submits a Teleporter message that invokes `createBridgeNFT` on the destination chain.
        - `_createBridgeNFTContract`: Called when a new `BridgeAction.Create` Teleporter message is received on the destinations chain. Deploys a new `BridgeNFT` contract to represent a native ERC721 token, if it already does not exist.
        - `bridgeToken`: Called to move supported ERC721 token from one chain to another. If a token is moved from native to bridged contract, the ERC721 token is locked on the native chain by being transferred to the ERC721Bridge (requires the ERC721Bridge to be approved as operator of the token) and then minted to the used on the destination chain. If a token is moved from a bridged contract to a native contract, the bridged ERC721 token is burned (also requires approve) on the bridge chain and then "unlocked" by being transferred back to the recipient on the native chain.
        - `_mintBridgeNFT`: Called when a new `BridgeAction.Mint` Teleporter message is received on the destinations chain to mint the bridged ERC721 token to the receiver address.
        - `_transferBridgeNFT`: Called when a new `BridgeAction.Transfer` Teleporter message is received to transfer bridged tokens to the native chain.

Note: This implementation currently does not support chain-hopping for ERC721 tokens. This means if a user wants to re-bridge an ERC721 token from one chain to another, they must first bridge it back to the native chain and then bridge it to the new destination chain manually.

## End-to-end test
An end-to-end test demonstrating the use of the generic ERC721 token bridge contracts can be found in [here](/tests/flows/erc721_native_token_bridge.go). This test implements the following flow and checks that each step is successful:
1. An example "native" [ERC721](/contracts/src/Mocks/ExampleERC721.sol) token is deployed on subnet A
2. The [ERC721Bridge](/contracts/src/CrossChainApplications/examples/ERC721Bridge/ERC721Bridge.sol) contract is deployed on subnets A and B.
4. Teleporter message is sent from subnet A to B to create a new [BridgeNFT](/contracts/misc/erc721-bridge/BridgeNFT.sol) contract instance to represent the native ERC721 token on subnet B.
5. An NFT is minted on subnet A to the user address.
6. ERC721Bridge on subnet A is approved as operator of the NFT.
7. `bridgeToken` is called on subnet A to lock the NFT and bridge it to subnet B.
8. The NFT is transferred to the ERC721Bridge contract on subnet A and then a Teleporter message is sent to subnet B to mint the NFT to the user on the BridgeNFT contract on subnet B.
9. The user on subnet B approves the BridgeNFT contract on subnet B as operator of the NFT.
10. The user on subnet B calls `bridgeToken` on the BridgeNFT contract on subnet B to burn the NFT and bridge it to subnet A.

## Local testing
1. Run a local network following the instructions [here](/README.md#run-a-local-testnet-in-docker).
2. An example workflow is provided via the [erc721_send_and_receive.sh](scripts/local/examples/basic_send_receive.sh) script.
