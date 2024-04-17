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
 * @title TeleporterTokenSource
 * @dev Abstract contract for a Teleporter token bridge that sends tokens to {TeleporterTokenDestination} instances.
 *
 * This contract also handles multihop transfers, where tokens sent from a {TeleporterTokenDestination}
 * instance are forwarded to another {TeleporterTokenDestination} instance.
 */
abstract contract TeleporterTokenSource is ITeleporterTokenBridge, TeleporterOwnerUpgradeable {
    /// @notice The blockchain ID of the chain this contract is deployed on.
    bytes32 public immutable blockchainID;

    /// @notice The ERC20 token this contract uses to pay for Teleporter fees.
    address public immutable feeTokenAddress;

    /**
     * @notice Tracks the balances of tokens sent to other bridge instances.
     * Bridges are not allowed to unwrap more than has been sent to them.
     * @dev (destinationBlockchainID, destinationBridgeAddress) -> balance
     */
    mapping(bytes32 destinationBlockchainID => mapping(address destinationBridgeAddress => uint256 balance)) public
        bridgedBalances;

    // TODO: these are values brought from the example ERC20Bridge contract.
    // Need to figure out appropriate values.
    uint256 public constant SEND_TOKENS_REQUIRED_GAS = 300_000;

    /**
     * @notice Initializes this source token bridge instance to send
     * tokens to the specified destination chain and token bridge instance.
     */
    constructor(address teleporterRegistryAddress, address teleporterManager, address feeTokenAddress_)
        TeleporterOwnerUpgradeable(teleporterRegistryAddress, teleporterManager)
    {
        blockchainID = IWarpMessenger(0x0200000000000000000000000000000000000005).getBlockchainID();
        require(feeTokenAddress_ != address(0), "TeleporterTokenSource: zero fee token address");
        feeTokenAddress = feeTokenAddress_;
    }

    /**
     * @notice Sends tokens to the specified destination token bridge instance.
     *
     * @dev Increases the bridge balance sent to each destination token bridge instance,
     * and uses Teleporter to send a cross chain message.
     * Requirements:
     *
     * - `input.destinationBlockchainID` cannot be the same as the current blockchainID
     * - `input.destinationBridgeAddress` cannot be the zero address
     * - `input.recipient` cannot be the zero address
     * - `amount` must be greater than 0
     * - `amount` must be greater than `input.primaryFee`
     */
    function _send(SendTokensInput memory input, uint256 amount, bool isMultihop) internal virtual {
        require(input.destinationBlockchainID != blockchainID, "TeleporterTokenSource: cannot bridge to same chain");
        require(input.destinationBridgeAddress != address(0), "TeleporterTokenSource: zero destination bridge address");
        require(input.recipient != address(0), "TeleporterTokenSource: zero recipient address");

        // If this send is not a multihop, deposit the funds sent from the user to the bridge,
        // and set to adjusted amount after deposit. If it is a multihop, the amount is already
        // deposited.
        if (!isMultihop) {
            amount = _deposit(amount);
        }
        require(amount > 0, "TeleporterTokenSource: zero send amount");
        require(amount > input.primaryFee, "TeleporterTokenSource: insufficient amount to cover fees");

        // Subtract fee amount from amount and increase bridge balance
        amount -= input.primaryFee;
        bridgedBalances[input.destinationBlockchainID][input.destinationBridgeAddress] += amount;

        // send message to destinationBridgeAddress
        bytes32 messageID = _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: input.destinationBlockchainID,
                destinationAddress: input.destinationBridgeAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: feeTokenAddress, amount: input.primaryFee}),
                // TODO: Set requiredGasLimit
                requiredGasLimit: SEND_TOKENS_REQUIRED_GAS,
                allowedRelayerAddresses: input.allowedRelayerAddresses,
                message: abi.encode(input.recipient, amount)
            })
        );

        emit SendTokens(messageID, msg.sender, amount);
    }

    /**
     * @dev See {ITeleporterUpgradeable-_receiveTeleporterMessage}
     *
     * Verifies the Teleporter token bridge sending back tokens has enough balance,
     * and adjusts the bridge balance accordingly. If the final destination for this token
     * is this contract, the tokens are withdrawn and sent to the recipient. Otherwise,
     * a multihop is performed, and the tokens are forwarded to the destination token bridge.
     * Requirements:
     *
     * - `sourceBlockchainID` and `originSenderAddress` have enough bridge balance to send back.
     * - `input.destinationBridgeAddress` is this contract is this chain is the final destination.
     */
    function _receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes memory message)
        internal
        virtual
        override
    {
        (SendTokensInput memory input, uint256 amount) = abi.decode(message, (SendTokensInput, uint256));

        // Check that bridge instance returning has sufficient amount in balance
        uint256 senderBalance = bridgedBalances[sourceBlockchainID][originSenderAddress];
        require(senderBalance >= amount, "TeleporterTokenSource: insufficient bridge balance");

        // Decrement the bridge balance by the unwrap amount
        bridgedBalances[sourceBlockchainID][originSenderAddress] = senderBalance - amount;

        // If the final destination of the transfer is this source bridge instance, withdraw the tokens.abi
        // Otherwise, perform a multihop transfer to the input destination bridge instance.
        if (input.destinationBlockchainID == blockchainID) {
            require(input.destinationBridgeAddress == address(this), "TeleporterTokenSource: invalid bridge address");
            _withdraw(input.recipient, amount);
            return;
        }

        _send(input, amount, true);
    }

    function _deposit(uint256 amount) internal virtual returns (uint256);

    function _withdraw(address recipient, uint256 amount) internal virtual;
}
