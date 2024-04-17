// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {TeleporterOwnerUpgradeable} from "@teleporter/upgrades/TeleporterOwnerUpgradeable.sol";
import {ITeleporterTokenBridge, SendTokensInput} from "./interfaces/ITeleporterTokenBridge.sol";
import {IWarpMessenger} from "@avalabs/subnet-evm-contracts@1.2.0/contracts/interfaces/IWarpMessenger.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @title TeleporterTokenDestination
 * @dev Abstract contract for a Teleporter token bridge that receives tokens from a {TeleporterTokenSource} in exchange for the tokens of this token bridge instance.
 */
abstract contract TeleporterTokenDestination is ITeleporterTokenBridge, TeleporterOwnerUpgradeable {
    /// @notice The blockchain ID of the chain this contract is deployed on.
    bytes32 public immutable blockchainID;

    /// @notice The blockchain ID of the source chain this contract receives tokens from.
    bytes32 public immutable sourceBlockchainID;
    /// @notice The address of the source token bridge instance this contract receives tokens from.
    address public immutable tokenSourceAddress;
    /// @notice The ERC20 token this contract uses to pay for Teleporter fees.
    address public immutable feeTokenAddress;

    // TODO: these are values brought from the example ERC20Bridge contract.
    // Need to figure out appropriate values.
    uint256 public constant SEND_TOKENS_REQUIRED_GAS = 300_000;

    /**
     * @notice Initializes this destination token bridge instance to receive
     * tokens from the specified source blockchain and token bridge instance.
     */
    constructor(
        address teleporterRegistryAddress,
        address teleporterManager,
        bytes32 sourceBlockchainID_,
        address tokenSourceAddress_,
        address feeTokenAddress_
    ) TeleporterOwnerUpgradeable(teleporterRegistryAddress, teleporterManager) {
        blockchainID = IWarpMessenger(0x0200000000000000000000000000000000000005).getBlockchainID();
        require(sourceBlockchainID_ != bytes32(0), "TeleporterTokenDestination: zero source blockchain ID");
        require(
            sourceBlockchainID_ != blockchainID,
            "TeleporterTokenDestination: cannot deploy to same blockchain as source"
        );
        require(tokenSourceAddress_ != address(0), "TeleporterTokenDestination: zero token source address");
        require(feeTokenAddress_ != address(0), "TeleporterTokenDestination: zero fee token address");
        sourceBlockchainID = sourceBlockchainID_;
        tokenSourceAddress = tokenSourceAddress_;
        feeTokenAddress = feeTokenAddress_;
    }

    /**
     * @notice Sends tokens to the specified destination token bridge instance.
     *
     * @dev Burns the bridged amount, and uses Teleporter to send a cross chain message.
     * Tokens can be sent to the same blockchain this bridge instance is deployed on,
     * to another destination bridge instance.
     * Requirements:
     *
     * - `input.destinationBridgeAddress` cannot be the zero address
     * - `input.recipient` cannot be the zero address
     * - `amount` must be greater than 0
     * - `amount` must be greater than `input.primaryFee`
     */
    function _send(SendTokensInput calldata input, uint256 amount) internal virtual {
        require(
            input.destinationBridgeAddress != address(0), "TeleporterTokenDestination: zero destination bridge address"
        );
        require(input.recipient != address(0), "TeleporterTokenDestination: zero recipient address");

        // If the destination blockchain is the source bridge instance's blockchain,
        // the destination bridge address must match the token source address.
        if (input.destinationBlockchainID == sourceBlockchainID) {
            require(
                input.destinationBridgeAddress == tokenSourceAddress,
                "TeleporterTokenDestination: invalid destination bridge address"
            );
        } else if (input.destinationBlockchainID == blockchainID) {
            require(
                input.destinationBridgeAddress != address(this),
                "TeleporterTokenDestination: invalid destination bridge address"
            );
        }

        // Deposit the funds sent from the user to the bridge,
        // and set to adjusted amount after deposit
        amount = _deposit(amount);
        require(amount > 0, "TeleporterTokenDestination: zero send amount");
        require(
            amount > input.primaryFee + input.secondaryFee,
            "TeleporterTokenDestination: insufficient amount to cover fees"
        );

        // TODO: For NativeTokenDestination before this _send, we should exchange the fee amount
        // in native tokens for the fee amount in erc20 tokens. For ERC20Destination, we simply
        // safeTransferFrom the full amount.
        amount -= input.primaryFee;
        _burn(amount);

        bytes32 messageID = _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: sourceBlockchainID,
                destinationAddress: tokenSourceAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: feeTokenAddress, amount: input.primaryFee}),
                // TODO: placeholder value
                requiredGasLimit: SEND_TOKENS_REQUIRED_GAS,
                allowedRelayerAddresses: input.allowedRelayerAddresses,
                message: abi.encode(
                    SendTokensInput({
                        destinationBlockchainID: input.destinationBlockchainID,
                        destinationBridgeAddress: input.destinationBridgeAddress,
                        recipient: input.recipient,
                        primaryFee: input.secondaryFee,
                        secondaryFee: 0,
                        // TODO: Does multihop allowed relayer need to be separate parameter?
                        allowedRelayerAddresses: input.allowedRelayerAddresses
                    }),
                    amount
                    )
            })
        );

        emit SendTokens(messageID, msg.sender, amount);
    }

    /**
     * @notice Verifies the source token bridge instance, and withdraws the amount to the recipient address.
     *
     * @dev See {ITeleporterUpgradeable-_receiveTeleporterMessage}
     */
    function _receiveTeleporterMessage(bytes32 sourceBlockchainID_, address originSenderAddress, bytes memory message)
        internal
        virtual
        override
    {
        require(sourceBlockchainID_ == sourceBlockchainID, "TeleporterTokenDestination: invalid source chain");
        require(originSenderAddress == tokenSourceAddress, "TeleporterTokenDestination: invalid token source address");
        (address recipient, uint256 amount) = abi.decode(message, (address, uint256));

        _withdraw(recipient, amount);
    }

    /**
     * @notice Deposits tokens from the sender to this contract,
     * and returns the adjusted amount of tokens deposited.
     * @param amount is initial amount sent to this contract.
     * @return The actual amount deposited to this contract.
     */
    function _deposit(uint256 amount) internal virtual returns (uint256);

    /**
     * @notice Withdraws tokens to the recipient address.
     * @param recipient The address to withdraw tokens to
     * @param amount The amount of tokens to withdraw
     */
    function _withdraw(address recipient, uint256 amount) internal virtual;

    /**
     * @notice Burns a fee adjusted amount of tokens that the user
     * has deposited to this token bridge instance.
     * @param amount The amount of tokens to burn
     */
    function _burn(uint256 amount) internal virtual;
}
