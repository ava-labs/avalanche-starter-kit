// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import {BridgeNFT} from "./BridgeNFT.sol";
import {ExampleERC721} from "./ExampleERC721.sol";
import {IERC721Bridge} from "./IERC721Bridge.sol";
import {ITeleporterMessenger, TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {TeleporterOwnerUpgradeable} from "@teleporter/upgrades/TeleporterOwnerUpgradeable.sol";
import {IWarpMessenger} from "@avalabs/subnet-evm-contracts@1.2.0/contracts/interfaces/IWarpMessenger.sol";
import {IERC721} from "@openzeppelin/contracts@4.8.1/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts@4.8.1/token/ERC721/IERC721Receiver.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/utils/SafeERC20.sol";
import {SafeERC20TransferFrom} from "@teleporter/SafeERC20TransferFrom.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @dev Implementation of the {IERC721Bridge} interface.
 *
 * This implementation uses the {BridgeToken} contract to represent tokens on this chain, and uses
 * {ITeleporterMessenger} to send and receive messages to other chains.
 */
contract ERC721Bridge is IERC721Bridge, TeleporterOwnerUpgradeable, IERC721Receiver {
    using SafeERC20 for IERC20;

    address public constant WARP_PRECOMPILE_ADDRESS = 0x0200000000000000000000000000000000000005;
    bytes32 public immutable currentBlockchainID;
    uint256 public constant CREATE_BRIDGE_TOKENS_REQUIRED_GAS = 2_000_000;
    uint256 public constant MINT_BRIDGE_TOKENS_REQUIRED_GAS = 200_000;
    uint256 public constant TRANSFER_BRIDGE_TOKENS_REQUIRED_GAS = 300_000;

    // Mapping to keep track of submitted create bridge token requests
    mapping(
        bytes32 destinationBlockchainID
            => mapping(address destinationBridgeAddress => mapping(address erc721Contract => bool submitted))
    ) public submittedBridgeNFTCreations;

    // Set of BridgeNFT contracts created by this ERC721Bridge instance.
    mapping(address bridgeNFT => bool bridgeTokenExists) public bridgedNFTContracts;

    // Tracks the wrapped bridge token contract address for each native token bridged to this bridge instance.
    // (nativeBlockchainID, nativeBridgeAddress, nativeTokenAddress) -> bridgeTokenAddress
    mapping(
        bytes32 nativeBlockchainID
            => mapping(address nativeBridgeAddress => mapping(address nativeTokenAddress => address bridgeNFTAddress))
    ) public nativeToBridgedNFT;

    mapping(address bridgeNft => mapping(uint256 tokenId => bool bridged)) public bridgedTokens;

    /**
     * @dev Initializes the Teleporter Messenger used for sending and receiving messages,
     * and initializes the current chain ID.
     */
    constructor(address teleporterRegistryAddress) TeleporterOwnerUpgradeable(teleporterRegistryAddress, msg.sender) {
        currentBlockchainID = IWarpMessenger(WARP_PRECOMPILE_ADDRESS).getBlockchainID();
    }

    // Required in order to be able to hold ERC721 tokens in this contract.
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC721Bridge-bridgeToken}.
     *
     * Requirements:
     *
     * - `destinationBlockchainID` cannot be the same as the current chain ID.
     * - `recipient` cannot be the zero address.
     * - `destinationBridgeAddress` cannot be the zero address.
     * - `tokenContractAddress` must be a valid ERC721 contract.
     * - `tokenId` must be a valid token ID for the ERC721 contract.
     *
     * Emits a {BridgeToken} event.
     */
    function bridgeToken(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        address tokenContractAddress,
        address recipient,
        uint256 tokenId,
        address messageFeeAsset,
        uint256 messageFeeAmount
    ) external nonReentrant {
        // Bridging tokens within a single chain is not allowed.
        if (destinationBlockchainID == currentBlockchainID) {
            revert InvalidDestinationBlockchainId();
        }

        // Neither the recipient, nor the NFT contract, nor the Remote Bridge can be the zero address.
        if (tokenContractAddress == address(0)) {
            revert ZeroTokenContractAddress();
        }
        if (recipient == address(0)) {
            revert ZeroRecipientAddress();
        }
        if (destinationBridgeAddress == address(0)) {
            revert ZeroDestinationBridgeAddress();
        }

        ITeleporterMessenger teleporterMessenger = _getTeleporterMessenger();

        _manageFee(teleporterMessenger, messageFeeAsset, messageFeeAmount);

        // If the token to be bridged is a bridged NFT of this bridge,
        // then handle it by burning the NFT on this chain, and sending a message
        // back to the native chain.
        // Otherwise, handle it by locking the NFT in this bridge instance,
        // and sending a message to the destination to mint the equivalent NFT on the destination chain.
        if (bridgedNFTContracts[tokenContractAddress]) {
            return _processBridgedTokenTransfer(
                BridgedTokenTransferInfo({
                    destinationBlockchainID: destinationBlockchainID,
                    destinationBridgeAddress: destinationBridgeAddress,
                    teleporterMessenger: teleporterMessenger,
                    bridgedNFTContractAddress: tokenContractAddress,
                    recipient: recipient,
                    tokenId: tokenId,
                    messageFeeAsset: messageFeeAsset,
                    messageFeeAmount: messageFeeAmount
                })
            );
        }

        // Check if requests to create a BridgeNFT contract on the destination chain has been submitted.
        // This does not guarantee that the BridgeNFT contract has been created on the destination chain,
        // due to different factors preventing the message from being delivered, or the contract creation.
        if (!submittedBridgeNFTCreations[destinationBlockchainID][destinationBridgeAddress][tokenContractAddress]) {
            revert TokenContractNotBridged();
        }

        // Check that the token ID is not already bridged
        // If the owner of the token is this contract, then the token is already bridged.
        address tokenOwner = IERC721(tokenContractAddress).ownerOf(tokenId);
        if (tokenOwner == address(this) || tokenOwner != msg.sender) {
            revert InvalidTokenId();
        }

        // Lock the NFT by transferring it to this contract.
        IERC721(tokenContractAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        // Send a message to the destination chain and bridge to mint the equivalent NFT on the destination chain.
        _processNativeTokenTransfer(
            NativeTokenTransferInfo({
                destinationBlockchainID: destinationBlockchainID,
                destinationBridgeAddress: destinationBridgeAddress,
                teleporterMessenger: teleporterMessenger,
                nativeContractAddress: tokenContractAddress,
                recipient: recipient,
                tokenId: tokenId,
                messageFeeAsset: messageFeeAsset,
                messageFeeAmount: messageFeeAmount
            })
        );
    }

    /**
     * @dev See {IERC721Bridge-submitCreateBridgeNFT}.
     *
     * We allow for `submitCreateBridgeNFT` to be called multiple times with the same bridge and token
     * information because a previous message may have been dropped or otherwise selectively not delivered.
     * If the bridge token already exists on the destination, we are sending a message that will
     * simply have no effect on the destination.
     *
     * Emits a {SubmitCreateBridgeToken} event.
     */
    function submitCreateBridgeNFT(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        ExampleERC721 nativeContract,
        address messageFeeAsset,
        uint256 messageFeeAmount
    ) external nonReentrant {
        if (destinationBridgeAddress == address(0)) {
            revert ZeroDestinationBridgeAddress();
        }

        ITeleporterMessenger teleporterMessenger = _getTeleporterMessenger();

        _manageFee(teleporterMessenger, messageFeeAsset, messageFeeAmount);

        // Create the calldata to create an instance of BridgeNFT contract on the destination chain.
        bytes memory messageData = encodeCreateBridgeNFTData(
            CreateBridgeNFTData({
                nativeContractAddress: address(nativeContract),
                nativeName: nativeContract.name(),
                nativeSymbol: nativeContract.symbol(),
                nativeTokenURI: nativeContract.baseUri()
            })
        );

        // Send Teleporter message.
        bytes32 messageID = teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: destinationBlockchainID,
                destinationAddress: destinationBridgeAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: messageFeeAsset, amount: messageFeeAmount}),
                requiredGasLimit: CREATE_BRIDGE_TOKENS_REQUIRED_GAS,
                allowedRelayerAddresses: new address[](0),
                message: messageData
            })
        );

        // Update the mapping to keep track of submitted create bridge token requests
        submittedBridgeNFTCreations[destinationBlockchainID][destinationBridgeAddress][address(nativeContract)] = true;

        emit SubmitCreateBridgeNFT(
            destinationBlockchainID, destinationBridgeAddress, address(nativeContract), messageID
        );
    }

    function _manageFee(ITeleporterMessenger teleporterMessenger, address messageFeeAsset, uint256 messageFeeAmount)
        private
        returns (uint256 adjustedFeeAmount)
    {
        // For non-zero fee amounts, first transfer the fee to this contract, and then
        // allow the Teleporter contract to spend it.
        if (messageFeeAmount > 0) {
            if (messageFeeAsset == address(0)) {
                revert ZeroFeeAssetAddress();
            }

            adjustedFeeAmount = SafeERC20TransferFrom.safeTransferFrom(IERC20(messageFeeAsset), messageFeeAmount);
            IERC20(messageFeeAsset).safeIncreaseAllowance(address(teleporterMessenger), adjustedFeeAmount);
        }
    }

    /**
     * @dev prepares the calldata and sends teleporter message to mint the equivalent NFT on the destination chain.
     *
     * Emits a {BridgeToken} event.
     */
    function _processNativeTokenTransfer(NativeTokenTransferInfo memory transferInfo) private {
        bytes memory messageData = encodeMintBridgeNFTData(
            MintBridgeNFTData({
                nativeContractAddress: transferInfo.nativeContractAddress,
                recipient: transferInfo.recipient,
                tokenId: transferInfo.tokenId
            })
        );

        bytes32 messageID = transferInfo.teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: transferInfo.destinationBlockchainID,
                destinationAddress: transferInfo.destinationBridgeAddress,
                feeInfo: TeleporterFeeInfo({
                    feeTokenAddress: transferInfo.messageFeeAsset,
                    amount: transferInfo.messageFeeAmount
                }),
                requiredGasLimit: MINT_BRIDGE_TOKENS_REQUIRED_GAS,
                allowedRelayerAddresses: new address[](0),
                message: messageData
            })
        );

        emit BridgeToken(
            transferInfo.nativeContractAddress,
            transferInfo.destinationBlockchainID,
            messageID,
            transferInfo.destinationBridgeAddress,
            transferInfo.recipient,
            transferInfo.tokenId
        );
    }

    /**
     * @dev Encodes the parameters for the Mint action to be decoded and executed on the destination.
     */
    function encodeMintBridgeNFTData(MintBridgeNFTData memory mintData) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(mintData);

        return abi.encode(BridgeAction.Mint, paramsData);
    }

    /**
     * @dev Encodes the parameters for creating a BridgeNFT instance on the destination chain.
     */
    function encodeCreateBridgeNFTData(CreateBridgeNFTData memory createData) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(createData);

        return abi.encode(BridgeAction.Create, paramsData);
    }

    /**
     * @dev Process transfer of a bridged NFT to the native chain.
     *
     * It is the caller's responsibility to ensure that the wrapped token contract is supported by this bridge instance.
     * Emits a {BridgeTokens} event.
     */
    function _processBridgedTokenTransfer(BridgedTokenTransferInfo memory transferInfo) private {
        // Check that the token ID is bridged
        if (!bridgedTokens[transferInfo.bridgedNFTContractAddress][transferInfo.tokenId]) {
            revert InvalidTokenId();
        }

        // Burn the bridged tokenId to be transfered back to the native chain
        BridgeNFT bridgeNTF = BridgeNFT(transferInfo.bridgedNFTContractAddress);
        bridgeNTF.burn(transferInfo.tokenId);
        delete bridgedTokens[transferInfo.bridgedNFTContractAddress][
            transferInfo.tokenId
        ];

        // If the destination chain ID is the native chain ID for the wrapped token, the bridge address must also match.
        // This is because you are not allowed to bridge a token within its native chain.
        bytes32 nativeBlockchainID = bridgeNTF.nativeBlockchainID();
        address nativeBridgeAddress = bridgeNTF.nativeBridge();

        // Curently, we don't support hopping to a destination chain that is not the native chain of the wrapped token
        // until we figure out a better way to handle the fee.
        if (transferInfo.destinationBlockchainID != nativeBlockchainID) {
            revert InvalidDestinationBlockchainId();
        }

        if (transferInfo.destinationBridgeAddress != nativeBridgeAddress) {
            revert InvalidDestinationBridgeAddress();
        }

        // Send a message to the native chain and bridge of the wrapped asset that was burned.
        // The message includes the destination chain ID  and bridge contract, which will differ from the native
        // ones in the event that the tokens are being bridge from one non-native chain to another with two hops.
        bytes memory messageData = encodeTransferBridgeNFTData(
            TransferBridgeNFTData({
                destinationBlockchainID: transferInfo.destinationBlockchainID,
                destinationBridgeAddress: transferInfo.destinationBridgeAddress,
                nativeContractAddress: bridgeNTF.nativeAsset(),
                recipient: transferInfo.recipient,
                tokenId: transferInfo.tokenId
            })
        );

        bytes32 messageID = transferInfo.teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: nativeBlockchainID,
                destinationAddress: nativeBridgeAddress,
                feeInfo: TeleporterFeeInfo({
                    feeTokenAddress: transferInfo.messageFeeAsset,
                    amount: transferInfo.messageFeeAmount
                }),
                requiredGasLimit: TRANSFER_BRIDGE_TOKENS_REQUIRED_GAS,
                allowedRelayerAddresses: new address[](0),
                message: messageData
            })
        );

        emit BridgeToken(
            transferInfo.bridgedNFTContractAddress,
            transferInfo.destinationBlockchainID,
            messageID,
            transferInfo.destinationBridgeAddress,
            transferInfo.recipient,
            transferInfo.tokenId
        );
    }

    /**
     * @dev Encodes the parameters for the Transfer action to be decoded and executed on the destination.
     */
    function encodeTransferBridgeNFTData(TransferBridgeNFTData memory transferData)
        public
        pure
        returns (bytes memory)
    {
        // ABI encode the Transfer action and corresponding parameters for the transferBridgeToken
        // call to to be decoded and executed on the destination.
        bytes memory paramsData = abi.encode(transferData);

        return abi.encode(BridgeAction.Transfer, paramsData);
    }

    // TELEPORTER MESSAGE RECIEVER IMPLEMENTATION

    /**
     * @dev See {TeleporterUpgradeable-receiveTeleporterMessage}.
     *
     * Receives a Teleporter message and routes to the appropriate internal function call.
     */
    function _receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes memory message)
        internal
        override
    {
        // Decode the payload to recover the action and corresponding function parameters
        (BridgeAction action, bytes memory actionData) = abi.decode(message, (BridgeAction, bytes));

        // Route to the appropriate function.
        if (action == BridgeAction.Create) {
            CreateBridgeNFTData memory createData = abi.decode(actionData, (CreateBridgeNFTData));
            _createBridgeNFTContract(sourceBlockchainID, originSenderAddress, createData);
        } else if (action == BridgeAction.Mint) {
            MintBridgeNFTData memory mintData = abi.decode(actionData, (MintBridgeNFTData));
            _mintBridgeNFT(sourceBlockchainID, originSenderAddress, mintData);
        } else if (action == BridgeAction.Transfer) {
            TransferBridgeNFTData memory transferData = abi.decode(actionData, (TransferBridgeNFTData));
            _transferBridgeNFT(transferData);
        } else {
            revert InvalidBridgeAction();
        }
    }

    /**
     * @dev Teleporter message receiver for creating a new BridgeNFT contract on this chain.
     *
     * Emits a {CreateBridgeNFT} event.
     *
     * Note: This function is only called within `receiveTeleporterMessage`, which can only be
     * called by the Teleporter Messenger.
     */
    function _createBridgeNFTContract(
        bytes32 nativeBlockchainID,
        address nativeBridgeAddress,
        CreateBridgeNFTData memory createData
    ) private {
        // Check that the contract is not already bridged
        if (nativeToBridgedNFT[nativeBlockchainID][nativeBridgeAddress][createData.nativeContractAddress] != address(0))
        {
            revert TokenContractAlreadyBridged();
        }

        address bridgeERC721Address = address(
            new BridgeNFT({
                sourceBlockchainID: nativeBlockchainID,
                sourceBridge: nativeBridgeAddress,
                sourceAsset: createData.nativeContractAddress,
                tokenName: createData.nativeName,
                tokenSymbol: createData.nativeSymbol,
                tokenURI: createData.nativeTokenURI
            })
        );

        bridgedNFTContracts[bridgeERC721Address] = true;
        nativeToBridgedNFT[nativeBlockchainID][nativeBridgeAddress][createData.nativeContractAddress] =
            bridgeERC721Address;

        emit CreateBridgeNFT(
            nativeBlockchainID, nativeBridgeAddress, createData.nativeContractAddress, bridgeERC721Address
        );
    }

    /**
     * @dev Teleporter message receiver for minting a tokenId from the specified instance of the BridgeNFT contract.
     *
     * Emits a {MintBridgeNFT} event.
     *
     * Note: This function is only called within `receiveTeleporterMessage`, which can only be
     * called by the Teleporter Messenger.
     */
    function _mintBridgeNFT(bytes32 nativeBlockchainID, address nativeBridgeAddress, MintBridgeNFTData memory mintData)
        private
    {
        // The recipient cannot be the zero address.
        if (mintData.recipient == address(0)) {
            revert ZeroRecipientAddress();
        }
        // Check that a bridge token exists for this native asset.
        // If not, one needs to be created by the delivery of a "createBridgeToken" message first
        // before this mint can be processed. Once the bridge token is create, this message
        // could then be retried to mint the tokens.
        address bridgeNFTAddress =
            nativeToBridgedNFT[nativeBlockchainID][nativeBridgeAddress][mintData.nativeContractAddress];

        if (bridgeNFTAddress == address(0)) {
            revert TokenContractNotBridged();
        }

        // Mint the bridged NFT.
        BridgeNFT(bridgeNFTAddress).mint(mintData.recipient, mintData.tokenId);

        bridgedTokens[bridgeNFTAddress][mintData.tokenId] = true;

        emit MintBridgeNFT(bridgeNFTAddress, mintData.recipient, mintData.tokenId);
    }

    /**
     * @dev Teleporter message receiver for handling transfering bridged tokenId back to the native chain.
     *
     * Note: This function is only called within `receiveTeleporterMessage`, which can only be
     * called by the Teleporter Messenger.
     */
    function _transferBridgeNFT(TransferBridgeNFTData memory transferData) private {
        // Ensure that the destination blockchain ID is the current blockchain ID. No hops are supported at this time
        if (transferData.destinationBlockchainID != currentBlockchainID) {
            revert InvalidDestinationBlockchainId();
        }

        // Neither the recipient, nor the NFT contract, nor the Remote Bridge can be the zero address.
        if (transferData.nativeContractAddress == address(0)) {
            revert ZeroTokenContractAddress();
        }
        if (transferData.recipient == address(0)) {
            revert ZeroRecipientAddress();
        }
        if (transferData.destinationBridgeAddress == address(0)) {
            revert ZeroDestinationBridgeAddress();
        }

        // Transfer tokens to the recipient.
        IERC721(transferData.nativeContractAddress).safeTransferFrom(
            address(this), transferData.recipient, transferData.tokenId
        );
    }
}
