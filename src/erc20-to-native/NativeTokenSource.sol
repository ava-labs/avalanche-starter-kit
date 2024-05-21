// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {TeleporterTokenSource} from "./TeleporterTokenSource.sol";
import {INativeTokenBridge} from "./interfaces/INativeTokenBridge.sol";
import {INativeSendAndCallReceiver} from "./interfaces/INativeSendAndCallReceiver.sol";
import {
    SendTokensInput,
    SendAndCallInput,
    SingleHopCallMessage
} from "./interfaces/ITeleporterTokenBridge.sol";
import {IWrappedNativeToken} from "./interfaces/IWrappedNativeToken.sol";
import {CallUtils} from "./utils/CallUtils.sol";
import {SafeWrappedNativeTokenDeposit} from "./utils/SafeWrappedNativeTokenDeposit.sol";
import {Address} from "@openzeppelin/contracts@4.8.1/utils/Address.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @title NativeTokenSource
 * @notice This contract is an {INativeTokenBridge} that sends native tokens to another chain's
 * {ITeleporterTokenBridge} instance, and gets represented by the tokens of that destination
 * token bridge instance.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
contract NativeTokenSource is INativeTokenBridge, TeleporterTokenSource {
    using Address for address payable;

    /**
     * @notice The wrapped native token contract that represents the native tokens on this chain.
     */
    IWrappedNativeToken public immutable wrappedToken;

    /**
     * @notice Initializes this source token bridge instance to send
     * native tokens to other destination token bridges.
     * @param teleporterRegistryAddress The current blockchain ID's Teleporter registry
     * address. See here for details: https://github.com/ava-labs/teleporter/tree/main/contracts/src/Teleporter/upgrades
     * @param teleporterManager Address that manages this contract's integration with the
     * Teleporter registry and Teleporter versions.
     * @param wrappedTokenAddress The wrapped token contract address of the native asset
     * to be bridged to destination bridges.
     */
    constructor(
        address teleporterRegistryAddress,
        address teleporterManager,
        address wrappedTokenAddress
    ) TeleporterTokenSource(teleporterRegistryAddress, teleporterManager, wrappedTokenAddress) {
        wrappedToken = IWrappedNativeToken(wrappedTokenAddress);
    }

    /**
     * @notice Receives native tokens transferred to this contract.
     * @dev This function is called when the token bridge is withdrawing native tokens to
     * transfer to the recipient. The caller must be the wrapped native token contract.
     */
    receive() external payable {
        // The caller here is expected to be {tokenAddress} directly, and not through a meta-transaction,
        // so we check for `msg.sender` instead of `_msgSender()`.
        require(msg.sender == tokenAddress, "NativeTokenSource: invalid receive payable sender");
    }

    /**
     * @dev See {INativeTokenBridge-send}
     */
    function send(SendTokensInput calldata input) external payable {
        _send(input, msg.value, false);
    }

    /**
     * @dev See {INativeTokenBridge-sendAndCall}
     */
    function sendAndCall(SendAndCallInput calldata input) external payable {
        _sendAndCall({
            sourceBlockchainID: blockchainID,
            originBridgeAddress: address(this),
            originSenderAddress: _msgSender(),
            input: input,
            amount: msg.value,
            isMultiHop: false
        });
    }

    /**
     * @dev See {INativeTokenSource-addCollateral}
     */
    function addCollateral(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress
    ) external payable {
        _addCollateral(destinationBlockchainID, destinationBridgeAddress, msg.value);
    }

    /**
     * @dev See {TeleportTokenSource-_deposit}
     * Deposits the native tokens sent to this contract
     */
    function _deposit(uint256 amount) internal virtual override returns (uint256) {
        return SafeWrappedNativeTokenDeposit.safeDeposit(wrappedToken, amount);
    }

    /**
     * @dev See {TeleportTokenSource-_withdraw}
     * Withdraws the wrapped tokens for native tokens,
     * and sends them to the recipient.
     */
    function _withdraw(address recipient, uint256 amount) internal virtual override {
        emit TokensWithdrawn(recipient, amount);
        wrappedToken.withdraw(amount);
        payable(recipient).sendValue(amount);
    }

    /**
     * @dev See {TeleporterTokenDestination-_handleSendAndCall}
     *
     * Send the native tokens to the recipient contract as a part of the call to
     * {INativeSendAndCallReceiver-receiveTokens} on the recipient contract.
     * If the call fails or doesn't spend all of the tokens, the remaining amount is
     * sent to the fallback recipient.
     */
    function _handleSendAndCall(
        SingleHopCallMessage memory message,
        uint256 amount
    ) internal virtual override {
        // Withdraw the native token from the wrapped native token contract.
        wrappedToken.withdraw(amount);

        // Encode the call to {INativeSendAndCallReceiver-receiveTokens}
        bytes memory payload = abi.encodeCall(
            INativeSendAndCallReceiver.receiveTokens,
            (
                message.sourceBlockchainID,
                message.originBridgeAddress,
                message.originSenderAddress,
                message.recipientPayload
            )
        );

        // Call the destination contract with the given payload, gas amount, and value.
        bool success = CallUtils._callWithExactGasAndValue(
            message.recipientGasLimit, amount, message.recipientContract, payload
        );

        // If the call failed, send the funds to the fallback recipient.
        if (success) {
            emit CallSucceeded(message.recipientContract, amount);
        } else {
            emit CallFailed(message.recipientContract, amount);
            payable(message.fallbackRecipient).sendValue(amount);
        }
    }
}
