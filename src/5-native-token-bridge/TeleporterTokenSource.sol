// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {TeleporterOwnerUpgradeable} from "@teleporter/upgrades/TeleporterOwnerUpgradeable.sol";
import {
    ITeleporterTokenBridge,
    SendTokensInput,
    SendAndCallInput,
    BridgeMessageType,
    BridgeMessage,
    SingleHopSendMessage,
    SingleHopCallMessage,
    MultiHopSendMessage,
    MultiHopCallMessage
} from "./interfaces/ITeleporterTokenBridge.sol";
import {SendReentrancyGuard} from "./utils/SendReentrancyGuard.sol";
import {IWarpMessenger} from "@avalabs/subnet-evm-contracts@1.2.0/contracts/interfaces/IWarpMessenger.sol";
import {SafeERC20TransferFrom} from "@teleporter/SafeERC20TransferFrom.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @title TeleporterTokenSource
 * @dev Abstract contract for a Teleporter token bridge that sends tokens to {TeleporterTokenDestination} instances.
 *
 * This contract also handles multi-hop transfers, where tokens sent from a {TeleporterTokenDestination}
 * instance are forwarded to another {TeleporterTokenDestination} instance.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
abstract contract TeleporterTokenSource is ITeleporterTokenBridge, TeleporterOwnerUpgradeable, SendReentrancyGuard {
    /// @notice The blockchain ID of the chain this contract is deployed on.
    bytes32 public immutable blockchainID;

    /**
     * @notice The token address this source contract bridges to destination instances.
     * For multi-hop transfers, this `tokenAddress` is always used to pay for Teleporter fees.
     * If the token is an ERC20 token, the contract address is directly passed in.
     * If the token is a native asset, the contract address is the wrapped token contract.
     */
    address public immutable tokenAddress;

    /**
     * @notice Tracks the balances of tokens sent to other bridge instances.
     * Bridges are not allowed to unwrap more than has been sent to them.
     * @dev (destinationBlockchainID, destinationBridgeAddress) -> balance
     */
    mapping(bytes32 destinationBlockchainID => mapping(address destinationBridgeAddress => uint256 balance)) public
        bridgedBalances;

    /**
     * @notice Initializes this source token bridge instance to send
     * tokens to the specified destination chain and token bridge instance.
     */
    constructor(address teleporterRegistryAddress, address teleporterManager, address tokenAddress_)
        TeleporterOwnerUpgradeable(teleporterRegistryAddress, teleporterManager)
    {
        blockchainID = IWarpMessenger(0x0200000000000000000000000000000000000005).getBlockchainID();
        require(tokenAddress_ != address(0), "TeleporterTokenSource: zero token address");
        tokenAddress = tokenAddress_;
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
    function _send(SendTokensInput memory input, uint256 amount, bool isMultihop) internal sendNonReentrant {
        require(input.recipient != address(0), "TeleporterTokenSource: zero recipient address");
        require(input.requiredGasLimit > 0, "TeleporterTokenSource: zero required gas limit");
        require(input.secondaryFee == 0, "TeleporterTokenSource: non-zero secondary fee");
        (amount, input.primaryFee) = _prepareSend({
            destinationBlockchainID: input.destinationBlockchainID,
            destinationBridgeAddress: input.destinationBridgeAddress,
            amount: amount,
            feeTokenAddress: input.feeTokenAddress,
            feeAmount: input.primaryFee,
            isMultihop: isMultihop
        });

        BridgeMessage memory message = BridgeMessage({
            messageType: BridgeMessageType.SINGLE_HOP_SEND,
            amount: amount,
            payload: abi.encode(SingleHopSendMessage({recipient: input.recipient}))
        });

        // Send message to the destination bridge address
        bytes32 messageID = _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: input.destinationBlockchainID,
                destinationAddress: input.destinationBridgeAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: input.feeTokenAddress, amount: input.primaryFee}),
                requiredGasLimit: input.requiredGasLimit,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );

        if (isMultihop) {
            emit TokensRouted(messageID, input, amount);
        } else {
            emit TokensSent(messageID, msg.sender, input, amount);
        }
    }

    function _sendAndCall(
        bytes32 sourceBlockchainID,
        address originSenderAddress,
        SendAndCallInput memory input,
        uint256 amount,
        bool isMultihop
    ) internal sendNonReentrant {
        require(input.recipientContract != address(0), "TeleporterTokenSource: zero recipient contract address");
        require(input.requiredGasLimit > 0, "TeleporterTokenSource: zero required gas limit");
        require(input.recipientGasLimit > 0, "TeleporterTokenSource: zero recipient gas limit");
        require(input.recipientGasLimit < input.requiredGasLimit, "TeleporterTokenSource: invalid recipient gas limit");
        require(input.fallbackRecipient != address(0), "TeleporterTokenSource: zero fallback recipient address");
        (amount, input.primaryFee) = _prepareSend({
            destinationBlockchainID: input.destinationBlockchainID,
            destinationBridgeAddress: input.destinationBridgeAddress,
            amount: amount,
            feeTokenAddress: input.feeTokenAddress,
            feeAmount: input.primaryFee,
            isMultihop: isMultihop
        });

        BridgeMessage memory message = BridgeMessage({
            messageType: BridgeMessageType.SINGLE_HOP_CALL,
            amount: amount,
            payload: abi.encode(
                SingleHopCallMessage({
                    sourceBlockchainID: sourceBlockchainID,
                    originSenderAddress: originSenderAddress,
                    recipientContract: input.recipientContract,
                    recipientPayload: input.recipientPayload,
                    recipientGasLimit: input.recipientGasLimit,
                    fallbackRecipient: input.fallbackRecipient
                })
                )
        });

        // Send message to the destination bridge address
        bytes32 messageID = _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: input.destinationBlockchainID,
                destinationAddress: input.destinationBridgeAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: input.feeTokenAddress, amount: input.primaryFee}),
                requiredGasLimit: input.requiredGasLimit,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );

        if (isMultihop) {
            emit TokensAndCallRouted(messageID, input, amount);
        } else {
            emit TokensAndCallSent(messageID, originSenderAddress, input, amount);
        }
    }

    /**
     * @dev See {ITeleporterUpgradeable-_receiveTeleporterMessage}
     *
     * Verifies the Teleporter token bridge sending back tokens has enough balance,
     * and adjusts the bridge balance accordingly. If the final destination for this token
     * is this contract, the tokens are withdrawn and sent to the recipient. Otherwise,
     * a multi-hop is performed, and the tokens are forwarded to the destination token bridge.
     * Requirements:
     *
     * - `sourceBlockchainID` and `originSenderAddress` have enough bridge balance to send back.
     * - `input.destinationBridgeAddress` is this contract is this chain is the final destination.
     */
    function _receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes memory message)
        internal
        override
    {
        BridgeMessage memory bridgeMessage = abi.decode(message, (BridgeMessage));

        // Check that bridge instance returning has sufficient amount in balance
        uint256 senderBalance = bridgedBalances[sourceBlockchainID][originSenderAddress];
        require(senderBalance >= bridgeMessage.amount, "TeleporterTokenSource: insufficient bridge balance");

        // Decrement the bridge balance by the unwrap amount
        bridgedBalances[sourceBlockchainID][originSenderAddress] = senderBalance - bridgeMessage.amount;

        if (bridgeMessage.messageType == BridgeMessageType.SINGLE_HOP_SEND) {
            SingleHopSendMessage memory payload = abi.decode(bridgeMessage.payload, (SingleHopSendMessage));
            _withdraw(payload.recipient, bridgeMessage.amount);
            return;
        } else if (bridgeMessage.messageType == BridgeMessageType.SINGLE_HOP_CALL) {
            SingleHopCallMessage memory payload = abi.decode(bridgeMessage.payload, (SingleHopCallMessage));

            // Verify that the payload's source blockchain ID
            // matches the source blockchain ID passed from Teleporter.
            // Prevents a destination bridge from accessing tokens attributed
            // to another destination bridge instance.
            require(
                payload.sourceBlockchainID == sourceBlockchainID,
                "TeleporterTokenSource: mismatched source blockchain ID"
            );
            _handleSendAndCall(payload, bridgeMessage.amount);
            return;
        } else if (bridgeMessage.messageType == BridgeMessageType.MULTI_HOP_SEND) {
            MultiHopSendMessage memory payload = abi.decode(bridgeMessage.payload, (MultiHopSendMessage));

            // For a multi-hop send, the fee token address has to be `tokenAddress`,
            // because the fee is taken from the amount that has already been deposited.
            // For ERC20 tokens, the token address of the contract is directly passed.abi
            // For native assets, the contract address is the wrapped token contract.
            _send(
                SendTokensInput({
                    destinationBlockchainID: payload.destinationBlockchainID,
                    destinationBridgeAddress: payload.destinationBridgeAddress,
                    recipient: payload.recipient,
                    feeTokenAddress: tokenAddress,
                    primaryFee: payload.secondaryFee,
                    secondaryFee: 0,
                    requiredGasLimit: payload.secondaryGasLimit
                }),
                bridgeMessage.amount,
                true
            );
            return;
        } else if (bridgeMessage.messageType == BridgeMessageType.MULTI_HOP_CALL) {
            MultiHopCallMessage memory payload = abi.decode(bridgeMessage.payload, (MultiHopCallMessage));

            // For a multi-hop send, the fee token address has to be `tokenAddress`,
            // because the fee is taken from the amount that has already been deposited.
            // For ERC20 tokens, the token address of the contract is directly passed.abi
            // For native assets, the contract address is the wrapped token contract.
            _sendAndCall(
                sourceBlockchainID,
                payload.originSenderAddress,
                SendAndCallInput({
                    destinationBlockchainID: payload.destinationBlockchainID,
                    destinationBridgeAddress: payload.destinationBridgeAddress,
                    recipientContract: payload.recipientContract,
                    recipientPayload: payload.recipientPayload,
                    requiredGasLimit: payload.secondaryRequiredGasLimit,
                    recipientGasLimit: payload.recipientGasLimit,
                    fallbackRecipient: payload.fallbackRecipient,
                    feeTokenAddress: tokenAddress,
                    primaryFee: payload.secondaryFee,
                    secondaryFee: 0
                }),
                bridgeMessage.amount,
                true
            );
            return;
        }
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
     * @notice Processes a send and call message by calling the recipient contract.
     * @param message The send and call message include recipient calldata
     * @param amount The amount of tokens to be sent to the recipient
     */
    function _handleSendAndCall(SingleHopCallMessage memory message, uint256 amount) internal virtual;

    /**
     * @dev Prepares tokens to be sent to another chain by handling the
     * locking of the token amount in this contract and updating the accounting
     * balances.
     */
    function _prepareSend(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount,
        address feeTokenAddress,
        uint256 feeAmount,
        bool isMultihop
    ) private returns (uint256, uint256) {
        require(destinationBlockchainID != bytes32(0), "TeleporterTokenSource: zero destination blockchain ID");
        require(destinationBlockchainID != blockchainID, "TeleporterTokenSource: cannot bridge to same chain");
        require(destinationBridgeAddress != address(0), "TeleporterTokenSource: zero destination bridge address");

        // If this send is not a multi-hop, deposit the funds sent from the user to the bridge,
        // and set to adjusted amount after deposit.
        // If it is a multi-hop, the amount is already deposited.
        if (!isMultihop) {
            amount = _deposit(amount);
            if (feeAmount > 0) {
                feeAmount = SafeERC20TransferFrom.safeTransferFrom(IERC20(feeTokenAddress), feeAmount);
            }

            require(amount > 0, "TeleporterTokenSource: zero amount to send");
        } else {
            // Requiring the amount to cover fees for multi-hop sends,
            // because the fee is taken from the amount that has already been deposited.
            // This check also makes sure amount bridged is greater than zero.
            require(amount > feeAmount, "TeleporterTokenSource: insufficient amount to cover fees");
            amount -= feeAmount;
        }
        bridgedBalances[destinationBlockchainID][destinationBridgeAddress] += amount;

        return (amount, feeAmount);
    }
}
