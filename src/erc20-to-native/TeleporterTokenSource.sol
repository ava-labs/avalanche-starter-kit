// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {TeleporterOwnerUpgradeable} from "@teleporter/upgrades/TeleporterOwnerUpgradeable.sol";
import {ITeleporterTokenSource} from "./interfaces/ITeleporterTokenSource.sol";
import {
    SendTokensInput,
    SendAndCallInput,
    BridgeMessageType,
    BridgeMessage,
    SingleHopSendMessage,
    SingleHopCallMessage,
    MultiHopSendMessage,
    MultiHopCallMessage,
    RegisterDestinationMessage
} from "./interfaces/ITeleporterTokenBridge.sol";
import {SendReentrancyGuard} from "./utils/SendReentrancyGuard.sol";
import {TokenScalingUtils} from "./utils/TokenScalingUtils.sol";
import {IWarpMessenger} from
    "@avalabs/subnet-evm-contracts@1.2.0/contracts/interfaces/IWarpMessenger.sol";
import {SafeERC20TransferFrom} from "@teleporter/SafeERC20TransferFrom.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice Each destination bridge instance registers with the source token bridge contract,
 * and provides settings for bridging to the destination bridge.
 * @param registered Whether the destination bridge is registered
 * @param collateralNeeded The amount of tokens that must be first added as collateral,
 * through {addCollateral} calls, before tokens can be bridged to the destination token bridge.
 * @param tokenMultiplier The scaling factor for the amount of tokens to be bridged to the destination.
 * @param multiplyOnDestination Whether the scaling factor is multiplied or divided when sending to the destination.
 */
struct DestinationBridgeSettings {
    bool registered;
    uint256 collateralNeeded;
    uint256 tokenMultiplier;
    bool multiplyOnDestination;
}

/**
 * @title TeleporterTokenSource
 * @dev Abstract contract for a Teleporter token bridge that sends tokens to {TeleporterTokenDestination} instances.
 *
 * This contract also handles multi-hop transfers, where tokens sent from a {TeleporterTokenDestination}
 * instance are forwarded to another {TeleporterTokenDestination} instance.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
abstract contract TeleporterTokenSource is
    ITeleporterTokenSource,
    TeleporterOwnerUpgradeable,
    SendReentrancyGuard
{
    /// @notice The blockchain ID of the chain this contract is deployed on.
    bytes32 public immutable blockchainID;

    /**
     * @notice The token address this source contract bridges to destination instances.
     * For multi-hop transfers, this {tokenAddress} is always used to pay for the secondary message fees.
     * If the token is an ERC20 token, the contract address is directly passed in.
     * If the token is a native asset, the contract address is the wrapped token contract.
     */
    address public immutable tokenAddress;

    /**
     * @notice Tracks the settings for each destination bridge instance. Destination bridge instances
     * must register with their {TeleporterTokenSource} contracts via Teleporter message to be able to
     * receive tokens from this contract.
     */
    mapping(
        bytes32 destinationBlockchainID
            => mapping(
                address destinationBridgeAddress => DestinationBridgeSettings destinationSettings
            )
    ) public registeredDestinations;

    /**
     * @notice Tracks the balances of tokens sent to other bridge instances.
     * Balances are represented in the destination token's denomination,
     * and bridges are not allowed to unwrap more than has been sent to them.
     * @dev (destinationBlockchainID, destinationBridgeAddress) -> balance
     */
    mapping(
        bytes32 destinationBlockchainID
            => mapping(address destinationBridgeAddress => uint256 balance)
    ) public bridgedBalances;

    uint256 public constant MAX_TOKEN_MULTIPLIER = 1e18;

    /**
     * @notice Initializes this source token bridge instance to send
     * tokens to the specified destination chain and token bridge instance.
     */
    constructor(
        address teleporterRegistryAddress,
        address teleporterManager,
        address tokenAddress_
    ) TeleporterOwnerUpgradeable(teleporterRegistryAddress, teleporterManager) {
        blockchainID = IWarpMessenger(0x0200000000000000000000000000000000000005).getBlockchainID();
        require(tokenAddress_ != address(0), "TeleporterTokenSource: zero token address");
        tokenAddress = tokenAddress_;
    }

    function _registerDestination(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 initialReserveImbalance,
        uint256 tokenMultiplier,
        bool multiplyOnDestination
    ) internal {
        require(
            destinationBlockchainID != bytes32(0),
            "TeleporterTokenSource: zero destination blockchain ID"
        );
        require(
            destinationBlockchainID != blockchainID,
            "TeleporterTokenSource: cannot register bridge on same chain"
        );
        require(
            destinationBridgeAddress != address(0),
            "TeleporterTokenSource: zero destination bridge address"
        );
        require(
            tokenMultiplier > 0 && tokenMultiplier < MAX_TOKEN_MULTIPLIER,
            "TeleporterTokenSource: invalid token multiplier"
        );
        require(
            !registeredDestinations[destinationBlockchainID][destinationBridgeAddress].registered,
            "TeleporterTokenSource: destination already registered"
        );

        // Calculate the collateral needed in source token denomination.
        uint256 collateralNeeded = TokenScalingUtils.removeTokenScale(
            tokenMultiplier, multiplyOnDestination, initialReserveImbalance
        );

        // Round up the collateral needed by 1 in the case that {multiplyOnDestination} is true and
        // {initialReserveImbalance} is not divisible by the {tokenMultiplier} to
        // ensure that the full amount is accounted for.
        if (multiplyOnDestination && initialReserveImbalance % tokenMultiplier != 0) {
            collateralNeeded += 1;
        }

        registeredDestinations[destinationBlockchainID][destinationBridgeAddress] =
        DestinationBridgeSettings({
            registered: true,
            collateralNeeded: collateralNeeded,
            tokenMultiplier: tokenMultiplier,
            multiplyOnDestination: multiplyOnDestination
        });

        emit DestinationRegistered(
            destinationBlockchainID,
            destinationBridgeAddress,
            collateralNeeded,
            tokenMultiplier,
            multiplyOnDestination
        );
    }

    /**
     * @notice Sends tokens to the specified destination token bridge instance.
     *
     * @dev Increases the bridge balance sent to each destination token bridge instance,
     * and uses Teleporter to send a cross chain message. The amount passed is assumed to
     * be already scaled to the local denomination for this token source.
     * Requirements:
     *
     * - {input.destinationBlockchainID} cannot be the same as the current blockchainID
     * - {input.destinationBridgeAddress} cannot be the zero address
     * - {input.recipient} cannot be the zero address
     * - {amount} must be greater than 0
     */
    function _send(
        SendTokensInput memory input,
        uint256 amount,
        bool isMultiHop
    ) internal sendNonReentrant {
        require(input.recipient != address(0), "TeleporterTokenSource: zero recipient address");
        require(input.requiredGasLimit > 0, "TeleporterTokenSource: zero required gas limit");
        require(input.secondaryFee == 0, "TeleporterTokenSource: non-zero secondary fee");

        uint256 adjustedAmount;
        uint256 feeAmount = input.primaryFee;
        if (isMultiHop) {
            adjustedAmount = _prepareMultiHopRouting(
                input.destinationBlockchainID,
                input.destinationBridgeAddress,
                amount,
                input.primaryFee
            );

            if (adjustedAmount == 0) {
                // If the adjusted amount is zero for any reason (i.e. unsupported destination,
                // being scaled down to zero, etc.), send the tokens to the multi-hop fallback.
                _withdraw(input.multiHopFallback, amount);
                return;
            }
        } else {
            // Require that a single hop transfer does not have a multi-hop fallback recipient.
            require(
                input.multiHopFallback == address(0),
                "TeleporterTokenSource: non-zero multi-hop fallback"
            );
            (adjustedAmount, feeAmount) = _prepareSend({
                destinationBlockchainID: input.destinationBlockchainID,
                destinationBridgeAddress: input.destinationBridgeAddress,
                amount: amount,
                primaryFeeTokenAddress: input.primaryFeeTokenAddress,
                feeAmount: input.primaryFee
            });
        }

        BridgeMessage memory message = BridgeMessage({
            messageType: BridgeMessageType.SINGLE_HOP_SEND,
            payload: abi.encode(
                SingleHopSendMessage({recipient: input.recipient, amount: adjustedAmount})
                )
        });

        // Send message to the destination bridge address
        bytes32 messageID = _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: input.destinationBlockchainID,
                destinationAddress: input.destinationBridgeAddress,
                feeInfo: TeleporterFeeInfo({
                    feeTokenAddress: input.primaryFeeTokenAddress,
                    amount: feeAmount
                }),
                requiredGasLimit: input.requiredGasLimit,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );

        if (isMultiHop) {
            emit TokensRouted(messageID, input, adjustedAmount);
        } else {
            emit TokensSent(messageID, _msgSender(), input, adjustedAmount);
        }
    }

    function _sendAndCall(
        bytes32 sourceBlockchainID,
        address originBridgeAddress,
        address originSenderAddress,
        SendAndCallInput memory input,
        uint256 amount,
        bool isMultiHop
    ) internal sendNonReentrant {
        require(
            input.recipientContract != address(0),
            "TeleporterTokenSource: zero recipient contract address"
        );
        require(input.requiredGasLimit > 0, "TeleporterTokenSource: zero required gas limit");
        require(input.recipientGasLimit > 0, "TeleporterTokenSource: zero recipient gas limit");
        require(
            input.recipientGasLimit < input.requiredGasLimit,
            "TeleporterTokenSource: invalid recipient gas limit"
        );
        require(
            input.fallbackRecipient != address(0),
            "TeleporterTokenSource: zero fallback recipient address"
        );
        require(input.secondaryFee == 0, "TeleporterTokenSource: non-zero secondary fee");

        uint256 adjustedAmount;
        uint256 feeAmount = input.primaryFee;
        if (isMultiHop) {
            adjustedAmount = _prepareMultiHopRouting(
                input.destinationBlockchainID,
                input.destinationBridgeAddress,
                amount,
                input.primaryFee
            );

            if (adjustedAmount == 0) {
                // If the adjusted amount is zero for any reason (i.e. unsupported destination,
                // being scaled down to zero, etc.), send the tokens to the multi-hop fallback recipient.
                _withdraw(input.multiHopFallback, amount);
                return;
            }
        } else {
            // Require that a single hop transfer does not have a multi-hop fallback recipient.
            require(
                input.multiHopFallback == address(0),
                "TeleporterTokenSource: non-zero multi-hop fallback"
            );

            (adjustedAmount, feeAmount) = _prepareSend({
                destinationBlockchainID: input.destinationBlockchainID,
                destinationBridgeAddress: input.destinationBridgeAddress,
                amount: amount,
                primaryFeeTokenAddress: input.primaryFeeTokenAddress,
                feeAmount: input.primaryFee
            });
        }

        BridgeMessage memory message = BridgeMessage({
            messageType: BridgeMessageType.SINGLE_HOP_CALL,
            payload: abi.encode(
                SingleHopCallMessage({
                    sourceBlockchainID: sourceBlockchainID,
                    originBridgeAddress: originBridgeAddress,
                    originSenderAddress: originSenderAddress,
                    recipientContract: input.recipientContract,
                    amount: adjustedAmount,
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
                feeInfo: TeleporterFeeInfo({
                    feeTokenAddress: input.primaryFeeTokenAddress,
                    amount: feeAmount
                }),
                requiredGasLimit: input.requiredGasLimit,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );

        if (isMultiHop) {
            emit TokensAndCallRouted(messageID, input, adjustedAmount);
        } else {
            emit TokensAndCallSent(messageID, originSenderAddress, input, adjustedAmount);
        }
    }

    /**
     * @dev See {INativeTokenSource-addCollateral}
     */
    function _addCollateral(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount
    ) internal sendNonReentrant {
        DestinationBridgeSettings memory destinationSettings =
            registeredDestinations[destinationBlockchainID][destinationBridgeAddress];
        require(
            destinationSettings.registered,
            "TeleporterTokenSource: destination bridge not registered"
        );
        require(
            destinationSettings.collateralNeeded > 0,
            "TeleporterTokenSource: zero collateral needed"
        );

        // Deposit the full amount, and withdraw back to the sender if there is excess.
        amount = _deposit(amount);

        // Calculate the remaining collateral needed, any excess amount, and adjust
        // {amount} to represent the amount of tokens added as collateral.
        uint256 remainingCollateralNeeded;
        uint256 excessAmount;
        if (amount >= destinationSettings.collateralNeeded) {
            remainingCollateralNeeded = 0;
            excessAmount = amount - destinationSettings.collateralNeeded;
            amount = destinationSettings.collateralNeeded;
        } else {
            remainingCollateralNeeded = destinationSettings.collateralNeeded - amount;
        }

        // Update the remaining collateral needed.
        registeredDestinations[destinationBlockchainID][destinationBridgeAddress].collateralNeeded =
            remainingCollateralNeeded;
        emit CollateralAdded(
            destinationBlockchainID, destinationBridgeAddress, amount, remainingCollateralNeeded
        );

        // If there is excess amount, send it back to the sender.
        if (excessAmount > 0) {
            _withdraw(_msgSender(), excessAmount);
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
     * - {sourceBlockchainID} and {originSenderAddress} have enough bridge balance to send back.
     * - {input.destinationBridgeAddress} is this contract is this chain is the final destination.
     */
    function _receiveTeleporterMessage(
        bytes32 sourceBlockchainID,
        address originSenderAddress,
        bytes memory message
    ) internal override {
        BridgeMessage memory bridgeMessage = abi.decode(message, (BridgeMessage));
        if (bridgeMessage.messageType == BridgeMessageType.SINGLE_HOP_SEND) {
            SingleHopSendMessage memory payload =
                abi.decode(bridgeMessage.payload, (SingleHopSendMessage));

            uint256 sourceAmount =
                _processSingleHopTransfer(sourceBlockchainID, originSenderAddress, payload.amount);

            // Send the tokens to the recipient.
            _withdraw(payload.recipient, sourceAmount);
            return;
        } else if (bridgeMessage.messageType == BridgeMessageType.SINGLE_HOP_CALL) {
            SingleHopCallMessage memory payload =
                abi.decode(bridgeMessage.payload, (SingleHopCallMessage));

            uint256 sourceAmount =
                _processSingleHopTransfer(sourceBlockchainID, originSenderAddress, payload.amount);

            // Verify that the payload's source blockchain ID and origin bridge address matches the source blockchain ID
            // and origin sender address passed from Teleporter.
            require(
                payload.sourceBlockchainID == sourceBlockchainID,
                "TeleporterTokenSource: mismatched source blockchain ID"
            );
            require(
                payload.originBridgeAddress == originSenderAddress,
                "TeleporterTokenSource: mismatched origin sender address"
            );

            _handleSendAndCall(payload, sourceAmount);
            return;
        } else if (bridgeMessage.messageType == BridgeMessageType.MULTI_HOP_SEND) {
            MultiHopSendMessage memory payload =
                abi.decode(bridgeMessage.payload, (MultiHopSendMessage));

            (uint256 sourceAmount, uint256 fee) = _processMultiHopTransfer(
                sourceBlockchainID, originSenderAddress, payload.amount, payload.secondaryFee
            );

            // For a multi-hop send, the fee token address has to be {tokenAddress},
            // because the fee is taken from the amount that has already been deposited.
            // For ERC20 tokens, the token address of the contract is directly passed.
            // For native assets, the contract address is the wrapped token contract.
            _send(
                SendTokensInput({
                    destinationBlockchainID: payload.destinationBlockchainID,
                    destinationBridgeAddress: payload.destinationBridgeAddress,
                    recipient: payload.recipient,
                    primaryFeeTokenAddress: tokenAddress,
                    primaryFee: fee,
                    secondaryFee: 0,
                    requiredGasLimit: payload.secondaryGasLimit,
                    multiHopFallback: payload.multiHopFallback
                }),
                sourceAmount,
                true
            );
            return;
        } else if (bridgeMessage.messageType == BridgeMessageType.MULTI_HOP_CALL) {
            MultiHopCallMessage memory payload =
                abi.decode(bridgeMessage.payload, (MultiHopCallMessage));

            (uint256 sourceAmount, uint256 fee) = _processMultiHopTransfer(
                sourceBlockchainID, originSenderAddress, payload.amount, payload.secondaryFee
            );

            // For a multi-hop send, the fee token address has to be {tokenAddress},
            // because the fee is taken from the amount that has already been deposited.
            // For ERC20 tokens, the token address of the contract is directly passed.
            // For native assets, the contract address is the wrapped token contract.
            _sendAndCall({
                sourceBlockchainID: sourceBlockchainID,
                originBridgeAddress: originSenderAddress,
                originSenderAddress: payload.originSenderAddress,
                input: SendAndCallInput({
                    destinationBlockchainID: payload.destinationBlockchainID,
                    destinationBridgeAddress: payload.destinationBridgeAddress,
                    recipientContract: payload.recipientContract,
                    recipientPayload: payload.recipientPayload,
                    requiredGasLimit: payload.secondaryRequiredGasLimit,
                    recipientGasLimit: payload.recipientGasLimit,
                    multiHopFallback: payload.multiHopFallback,
                    fallbackRecipient: payload.fallbackRecipient,
                    primaryFeeTokenAddress: tokenAddress,
                    primaryFee: fee,
                    secondaryFee: 0
                }),
                amount: sourceAmount,
                isMultiHop: true
            });
            return;
        } else if (bridgeMessage.messageType == BridgeMessageType.REGISTER_DESTINATION) {
            RegisterDestinationMessage memory payload =
                abi.decode(bridgeMessage.payload, (RegisterDestinationMessage));
            _registerDestination(
                sourceBlockchainID,
                originSenderAddress,
                payload.initialReserveImbalance,
                payload.tokenMultiplier,
                payload.multiplyOnDestination
            );
        }
    }

    /**
     * @notice Deposits tokens from the sender to this contract,
     * and returns the adjusted amount of tokens deposited.
     * @param amount The initial amount sent to this contract.
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
     * @param amount The amount of tokens to be sent to the recipient. This amount is assumed to be
     * already scaled to the local denomination for this token source.
     */
    function _handleSendAndCall(
        SingleHopCallMessage memory message,
        uint256 amount
    ) internal virtual;

    /**
     * @notice Processes a received single hop transfer from a destination bridge instance.
     * Validates that the message is sent from a registered destination bridge instance,
     * and is already collateralized.
     * @param destinationBlockchainID The blockchain ID of the destination bridge instance.
     * @param destinationBridgeAddress The address of the destination bridge instance.
     * @param amount The amount of tokens sent back from destination, denominated by the
     * destination's token scale amount.
     */
    function _processSingleHopTransfer(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount
    ) private returns (uint256) {
        DestinationBridgeSettings memory destinationSettings =
            registeredDestinations[destinationBlockchainID][destinationBridgeAddress];

        return _processReceivedTransfer(
            destinationSettings, destinationBlockchainID, destinationBridgeAddress, amount
        );
    }

    /**
     * @notice Processes a received multi-hop transfer from a destination bridge instance.
     * Validates that the message is sent from a registered destination bridge instance,
     * and is already collateralized.
     * @param destinationBlockchainID The blockchain ID of the destination bridge instance.
     * @param destinationBridgeAddress The address of the destination bridge instance.
     * @param amount The amount of tokens sent back from destination, denominated by the
     * destination's token scale amount.
     * @param secondaryFee The Teleporter fee for the second hop of the mutihop transfer
     */
    function _processMultiHopTransfer(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount,
        uint256 secondaryFee
    ) private returns (uint256, uint256) {
        DestinationBridgeSettings memory destinationSettings =
            registeredDestinations[destinationBlockchainID][destinationBridgeAddress];

        uint256 transferAmount = _processReceivedTransfer(
            destinationSettings, destinationBlockchainID, destinationBridgeAddress, amount
        );

        uint256 fee = TokenScalingUtils.removeTokenScale(
            destinationSettings.tokenMultiplier,
            destinationSettings.multiplyOnDestination,
            secondaryFee
        );

        return (transferAmount, fee);
    }

    /**
     * @notice Processes a received transfer from a destination bridge instance.
     * Deducts the balance bridged to the given destination.
     * Removes the token scaling of the destination, checks the associated source token
     * amount is greater than zero, and returns the source token amount.
     * @param destinationSettings The bridge settings for the destination bridge we received the transfer from.
     * @param destinationBlockchainID The blockchain ID of the destination bridge instance.
     * @param destinationBridgeAddress The address of the destination bridge instance.
     * @param amount The amount of tokens sent back from destination, denominated by the
     * destination's token scale amount.
     */
    function _processReceivedTransfer(
        DestinationBridgeSettings memory destinationSettings,
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount
    ) private returns (uint256) {
        // Require that the destination bridge is registered and has no collateral needed.
        require(
            destinationSettings.registered,
            "TeleporterTokenSource: destination bridge not registered"
        );
        require(
            destinationSettings.collateralNeeded == 0,
            "TeleporterTokenSource: destination bridge not collateralized"
        );

        // Deduct the balance bridged to the given destination bridge address prior to scaling the amount.
        _deductSenderBalance(destinationBlockchainID, destinationBridgeAddress, amount);

        // Remove the token scaling of the destination and get source token amount.
        uint256 sourceAmount = TokenScalingUtils.removeTokenScale(
            destinationSettings.tokenMultiplier, destinationSettings.multiplyOnDestination, amount
        );

        // Require that the source token amount is greater than zero after removed scaling.
        require(sourceAmount > 0, "TeleporterTokenSource: zero token amount");
        return sourceAmount;
    }

    /**
     * @notice Prepares a multi-hop send by checking the destination bridge settings
     * and adjusting the amount to be sent.
     * @return The scaled amount to be sent to the destination bridge. If zero is returned,
     * the tokens are sent to the fallback recipient. Zero can be returned if the
     * destination is not registered, needs collateral, or the scaled amount is zero.
     */
    function _prepareMultiHopRouting(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount,
        uint256 fee
    ) private returns (uint256) {
        DestinationBridgeSettings memory destinationSettings =
            registeredDestinations[destinationBlockchainID][destinationBridgeAddress];
        if (!destinationSettings.registered || destinationSettings.collateralNeeded > 0) {
            return 0;
        }

        // Subtract fee amount from amount prior to scaling.
        require(amount > fee, "TeleporterTokenSource: insufficient amount to cover fees");
        amount -= fee;

        // Scale the amount based on the token multiplier for the given destination.
        uint256 scaledAmount = TokenScalingUtils.applyTokenScale(
            destinationSettings.tokenMultiplier, destinationSettings.multiplyOnDestination, amount
        );
        if (scaledAmount == 0) {
            return 0;
        }

        // Increase the balance of the destination bridge by the scaled amount.
        bridgedBalances[destinationBlockchainID][destinationBridgeAddress] += scaledAmount;

        return scaledAmount;
    }

    /**
     * @dev Prepares tokens to be sent to another chain by handling the
     * locking of the token amount in this contract and updating the accounting
     * balances.
     */
    function _prepareSend(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount,
        address primaryFeeTokenAddress,
        uint256 feeAmount
    ) private returns (uint256, uint256) {
        DestinationBridgeSettings memory destinationSettings =
            registeredDestinations[destinationBlockchainID][destinationBridgeAddress];
        require(destinationSettings.registered, "TeleporterTokenSource: destination not registered");
        require(
            destinationSettings.collateralNeeded == 0,
            "TeleporterTokenSource: collateral needed for destination"
        );

        // Deposit the funds sent from the user to the bridge,
        // and set to adjusted amount after deposit.
        amount = _deposit(amount);

        if (feeAmount > 0) {
            feeAmount =
                SafeERC20TransferFrom.safeTransferFrom(IERC20(primaryFeeTokenAddress), feeAmount);
        }

        // Scale the amount based on the token multiplier for the given destination.
        uint256 scaledAmount = TokenScalingUtils.applyTokenScale(
            destinationSettings.tokenMultiplier, destinationSettings.multiplyOnDestination, amount
        );
        require(scaledAmount > 0, "TeleporterTokenSource: zero scaled amount");

        // Increase the balance of the destination bridge by the scaled amount.
        bridgedBalances[destinationBlockchainID][destinationBridgeAddress] += scaledAmount;

        return (scaledAmount, feeAmount);
    }

    function _deductSenderBalance(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount
    ) private {
        uint256 senderBalance = bridgedBalances[destinationBlockchainID][destinationBridgeAddress];
        require(senderBalance >= amount, "TeleporterTokenSource: insufficient bridge balance");
        bridgedBalances[destinationBlockchainID][destinationBridgeAddress] = senderBalance - amount;
    }
}
