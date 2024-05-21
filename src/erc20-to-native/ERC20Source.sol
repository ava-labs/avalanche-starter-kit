// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {TeleporterTokenSource} from "./TeleporterTokenSource.sol";
import {IERC20Source} from "./interfaces/IERC20Source.sol";
import {IERC20SendAndCallReceiver} from "./interfaces/IERC20SendAndCallReceiver.sol";
import {SafeERC20TransferFrom} from "@teleporter/SafeERC20TransferFrom.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/utils/SafeERC20.sol";
import {
    SendTokensInput,
    SendAndCallInput,
    SingleHopCallMessage
} from "./interfaces/ITeleporterTokenBridge.sol";
import {CallUtils} from "./utils/CallUtils.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @title ERC20Source
 * @notice This contract is an {IERC20Source} that sends ERC20 tokens to another chain's
 * {ITeleporterTokenBridge} instance, and gets represented by the tokens of that destination
 * token bridge instance.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
contract ERC20Source is IERC20Source, TeleporterTokenSource {
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token this source contract bridges to destination instances.
    IERC20 public immutable token;

    /**
     * @notice Initializes this source token bridge instance to send ERC20
     * tokens to other destination token bridges.
     * @param teleporterRegistryAddress The current blockchain ID's Teleporter registry
     * address. See here for details: https://github.com/ava-labs/teleporter/tree/main/contracts/src/Teleporter/upgrades
     * @param teleporterManager Address that manages this contract's integration with the
     * Teleporter registry and Teleporter versions.
     * @param tokenAddress The ERC20 token contract address to bridge to the destination chain
     */
    constructor(
        address teleporterRegistryAddress,
        address teleporterManager,
        address tokenAddress
    ) TeleporterTokenSource(teleporterRegistryAddress, teleporterManager, tokenAddress) {
        token = IERC20(tokenAddress);
    }

    /**
     * @dev See {IERC20Bridge-send}
     */
    function send(SendTokensInput calldata input, uint256 amount) external {
        _send(input, amount, false);
    }

    /**
     * @dev See {IERC20Bridge-sendAndCall}
     */
    function sendAndCall(SendAndCallInput calldata input, uint256 amount) external {
        _sendAndCall({
            sourceBlockchainID: blockchainID,
            originBridgeAddress: address(this),
            originSenderAddress: _msgSender(),
            input: input,
            amount: amount,
            isMultiHop: false
        });
    }

    /**
     * @dev See {INativeTokenSource-addCollateral}
     */
    function addCollateral(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount
    ) external {
        _addCollateral(destinationBlockchainID, destinationBridgeAddress, amount);
    }

    /**
     * @dev See {TeleportTokenSource-_deposit}
     */
    function _deposit(uint256 amount) internal virtual override returns (uint256) {
        return SafeERC20TransferFrom.safeTransferFrom(token, amount);
    }

    /**
     * @dev See {TeleportTokenSource-_withdraw}
     */
    function _withdraw(address recipient, uint256 amount) internal virtual override {
        emit TokensWithdrawn(recipient, amount);
        token.safeTransfer(recipient, amount);
    }

    /**
     * @dev See {TeleporterTokenDestination-_handleSendAndCall}
     *
     * Approves the recipient contract to spend the amount of tokens from this contract,
     * and calls {IERC20SendAndCallReceiver-receiveTokens} on the recipient contract.
     * If the call fails or doesn't spend all of the tokens, the remaining amount is
     * sent to the fallback recipient.
     */
    function _handleSendAndCall(
        SingleHopCallMessage memory message,
        uint256 amount
    ) internal virtual override {
        // Approve the destination contract to spend the amount from the collateral.
        SafeERC20.safeIncreaseAllowance(token, message.recipientContract, amount);

        // Encode the call to {IERC20SendAndCallReceiver-receiveTokens}
        bytes memory payload = abi.encodeCall(
            IERC20SendAndCallReceiver.receiveTokens,
            (
                message.sourceBlockchainID,
                message.originBridgeAddress,
                message.originSenderAddress,
                address(token),
                amount,
                message.recipientPayload
            )
        );

        // Call the destination contract with the given payload and gas amount.
        bool success = CallUtils._callWithExactGas(
            message.recipientGasLimit, message.recipientContract, payload
        );

        uint256 remainingAllowance = token.allowance(address(this), message.recipientContract);

        // Reset the destination contract allowance to 0.
        // Use of {safeApprove} is okay to reset the allowance to 0.
        SafeERC20.safeApprove(token, message.recipientContract, 0);

        if (success) {
            emit CallSucceeded(message.recipientContract, amount);
        } else {
            emit CallFailed(message.recipientContract, amount);
        }

        // Transfer any remaining allowance to the fallback recipient. This will be the
        // full amount if the call failed.
        if (remainingAllowance > 0) {
            token.safeTransfer(message.fallbackRecipient, remainingAllowance);
        }
    }
}
