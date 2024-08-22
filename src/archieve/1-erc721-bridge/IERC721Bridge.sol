// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import {ExampleERC721} from "./ExampleERC721.sol";
import {ITeleporterMessenger} from "@teleporter/ITeleporterMessenger.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @dev Interface that describes functionalities for a cross-chain ERC20 bridge.
 */
interface IERC721Bridge {
    error InvalidBridgeAction();
    error InvalidDestinationBlockchainId();
    error InvalidDestinationBridgeAddress();
    error InvalidTokenId();
    error TokenContractAlreadyBridged();
    error TokenContractNotBridged();
    error ZeroTokenContractAddress();
    error ZeroRecipientAddress();
    error ZeroDestinationBridgeAddress();
    error ZeroFeeAssetAddress();

    struct BridgedTokenTransferInfo {
        bytes32 destinationBlockchainID;
        address destinationBridgeAddress;
        ITeleporterMessenger teleporterMessenger;
        address bridgedNFTContractAddress;
        address recipient;
        uint256 tokenId;
        address messageFeeAsset;
        uint256 messageFeeAmount;
    }

    struct NativeTokenTransferInfo {
        bytes32 destinationBlockchainID;
        address destinationBridgeAddress;
        ITeleporterMessenger teleporterMessenger;
        address nativeContractAddress;
        address recipient;
        uint256 tokenId;
        address messageFeeAsset;
        uint256 messageFeeAmount;
    }

    struct CreateBridgeNFTData {
        address nativeContractAddress;
        string nativeName;
        string nativeSymbol;
        string nativeTokenURI;
    }

    struct MintBridgeNFTData {
        address nativeContractAddress;
        address recipient;
        uint256 tokenId;
    }

    struct TransferBridgeNFTData {
        bytes32 destinationBlockchainID;
        address destinationBridgeAddress;
        address nativeContractAddress;
        address recipient;
        uint256 tokenId;
    }

    /**
     * @dev Enum representing the action to take on receiving a Teleporter message.
     */
    enum BridgeAction {
        Create,
        Mint,
        Transfer
    }

    /**
     * @dev Emitted when tokens are locked in this bridge contract to be bridged to another chain.
     */
    event BridgeToken(
        address indexed tokenContractAddress,
        bytes32 indexed destinationBlockchainID,
        bytes32 indexed teleporterMessageID,
        address destinationBridgeAddress,
        address recipient,
        uint256 tokenId
    );

    /**
     * @dev Emitted when submitting a request to create a new bridge token on another chain.
     */
    event SubmitCreateBridgeNFT(
        bytes32 indexed destinationBlockchainID,
        address indexed destinationBridgeAddress,
        address indexed nativeContractAddress,
        bytes32 teleporterMessageID
    );

    /**
     * @dev Emitted when creating a new bridge token.
     */
    event CreateBridgeNFT(
        bytes32 indexed nativeBlockchainID,
        address indexed nativeBridgeAddress,
        address indexed nativeContractAddress,
        address bridgeTokenAddress
    );

    /**
     * @dev Emitted when minting bridge tokens.
     */
    event MintBridgeNFT(address indexed contractAddress, address recipient, uint256 tokenId);

    /**
     * @dev Transfers ERC721 token to another chain.
     *
     * This can be wrapping, unwrapping, and transferring a wrapped token between two non-native chains.
     */
    function bridgeToken(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        address tokenContractAddress,
        address recipient,
        uint256 tokenId,
        address feeTokenAddress,
        uint256 feeAmount
    ) external;

    /**
     * @dev Creates a new bridge token on another chain.
     */
    function submitCreateBridgeNFT(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        ExampleERC721 nativeContract,
        address feeTokenAddress,
        uint256 feeAmount
    ) external;
}
