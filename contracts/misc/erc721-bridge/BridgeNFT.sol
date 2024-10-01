// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts@4.8.1/token/ERC721/ERC721.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
error Unauthorized();

/**
 * @dev BridgeNFT is an ERC721 token contract that is associated with a specific native chain bridge and asset, and is only mintable by the bridge contract on this chain.
 */
contract BridgeNFT is ERC721 {
    address public immutable bridgeContract;
    bytes32 public immutable nativeBlockchainID;
    address public immutable nativeBridge;
    address public immutable nativeAsset;
    string public nativeTokenURI;

    /**
     * @dev Initializes a BridgeNFT instance.
     */
    constructor(
        bytes32 sourceBlockchainID,
        address sourceBridge,
        address sourceAsset,
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenURI
    ) ERC721(tokenName, tokenSymbol) {
        bridgeContract = msg.sender;
        nativeBlockchainID = sourceBlockchainID;
        nativeBridge = sourceBridge;
        nativeAsset = sourceAsset;
        nativeTokenURI = tokenURI;
    }

    /**
     * @dev Mints tokens to `account` if called by original `bridgeContract`.
     */
    function mint(address account, uint256 tokenId) external {
        _authorize();
        _mint(account, tokenId);
    }

    function burn(uint256 tokenId) external {
        _authorize();

        require(_isApprovedOrOwner(msg.sender, tokenId), "BridgeNFT: caller is not token owner or approved");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return nativeTokenURI;
    }

    function _authorize() internal view {
        if (msg.sender != bridgeContract) {
            revert Unauthorized();
        }
    }
}
