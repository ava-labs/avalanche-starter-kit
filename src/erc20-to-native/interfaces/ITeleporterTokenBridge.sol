// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {ITeleporterReceiver} from "@teleporter/ITeleporterReceiver.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice Parameters for delivery of tokens to another chain and destination recipient.
 * @param destinationBlockchainID BlockchainID of the destination
 * @param destinationBridgeAddress Address of the destination token bridge instance
 * @param recipient Address of the recipient on the destination chain
 * @param primaryFeeTokenAddress Address of the ERC20 contract to optionally pay a Teleporter message fee
 * @param primaryFee Amount of tokens to pay as the optional Teleporter message fee
 * @param secondaryFee Amount of tokens to pay for Teleporter fee if a multi-hop is needed
 * @param requiredGasLimit Gas limit requirement for sending to a token bridge.
 * This is required because the gas requirement varies based on the token bridge instance
 * specified by {destinationBlockchainID} and {destinationBridgeAddress}.
 * @param multiHopFallback In the case of a multi-hop transfer, the address where the tokens
 * are sent on the source chain if the transfer is unable to be routed to its final destination.
 */
struct SendTokensInput {
    bytes32 destinationBlockchainID;
    address destinationBridgeAddress;
    address recipient;
    address primaryFeeTokenAddress;
    uint256 primaryFee;
    uint256 secondaryFee;
    uint256 requiredGasLimit;
    address multiHopFallback;
}

/**
 * @notice Parameters for briding tokens to another chain and calling a contract on that chain
 * @param destinationBlockchainID BlockchainID of the destination
 * @param destinationBridgeAddress Address of the destination token bridge instance
 * @param recipientContract The contract on the destination chain that will be called
 * @param recipientPayload The payload that will be provided to the recipient contract on the destination chain
 * @param requiredGasLimit The required amount of gas needed to deliver the message on its destination chain,
 * including token operations and the call to the recipient contract.
 * @param recipientGasLimit The amount of gas that will provided to the recipient contract on the destination chain,
 * which must be less than the requiredGasLimit of the message as a whole.
 * @param multiHopFallback In the case of a multi-hop transfer, the address where the tokens
 * are sent on the source chain if the transfer is unable to be routed to its final destination.
 * @param fallbackRecipient Address on the {destinationBlockchainID} where the bridged tokens are sent to if the call to the recipient contract fails.
 * @param primaryFeeTokenAddress Address of the ERC20 contract to optionally pay a Teleporter message fee
 * @param primaryFee Amount of tokens to pay for Teleporter fee on the chain that iniiated the transfer
 * @param secondaryFee Amount of tokens to pay for Teleporter fee if a multi-hop is needed
 */
struct SendAndCallInput {
    bytes32 destinationBlockchainID;
    address destinationBridgeAddress;
    address recipientContract;
    bytes recipientPayload;
    uint256 requiredGasLimit;
    uint256 recipientGasLimit;
    address multiHopFallback;
    address fallbackRecipient;
    address primaryFeeTokenAddress;
    uint256 primaryFee;
    uint256 secondaryFee;
}

enum BridgeMessageType {
    REGISTER_DESTINATION,
    SINGLE_HOP_SEND,
    SINGLE_HOP_CALL,
    MULTI_HOP_SEND,
    MULTI_HOP_CALL
}

/**
 * @dev The BridgeMessage struct is used to wrap messages between two bridge contracts
 * with their message type so that the receiving bridge contract can decode the payload.
 */
struct BridgeMessage {
    BridgeMessageType messageType;
    bytes payload;
}

/**
 * @dev Register destination message payloads are sent to the source bridge contract
 * to register a new destination chain and bridge contract.
 * @param initialReserveImbalance The initial reserve imbalance of the destination bridge contract to calculate associated collateral needed on source bridge contract.
 * @param tokenMultiplier The token multiplier to scale the amount of tokens sent to the destination.
 * @param multiplyOnDestination Whether the source bridge contract should multiply or divide
 * the amount of tokens before sending to the destination.
 */
struct RegisterDestinationMessage {
    uint256 initialReserveImbalance;
    uint256 tokenMultiplier;
    bool multiplyOnDestination;
}

/**
 * @dev Single hop send message payloads include the recipient address and bridged amount .
 * The destination chain and bridge address are defined by the Teleporter message.
 */
struct SingleHopSendMessage {
    address recipient;
    uint256 amount;
}

/**
 * @dev Single hop call message payloads include the required information to call
 * the target contract on the destination chain. The destination chain and bridge
 * address are defined by the Teleporter message. The message also includes the
 * blockchain ID and address of the original sender.
 */
struct SingleHopCallMessage {
    bytes32 sourceBlockchainID;
    address originBridgeAddress;
    address originSenderAddress;
    address recipientContract;
    uint256 amount;
    bytes recipientPayload;
    uint256 recipientGasLimit;
    address fallbackRecipient;
}

/**
 * @dev Multi hop send message payloads include the recipient address as well as all
 * the information the intermediate (source) chain bridge contract needs to route
 * the send message on to its final destination.
 */
struct MultiHopSendMessage {
    bytes32 destinationBlockchainID;
    address destinationBridgeAddress;
    address recipient;
    uint256 amount;
    uint256 secondaryFee;
    uint256 secondaryGasLimit;
    address multiHopFallback;
}

/**
 * @dev Multi hop call message payloads include the required information to call the target contract on the
 * destination chain, as well as the information the intermediate (source) chain bridge contract needs to route
 * the call message on to its final destination. This includes the secondaryRequiredGasLimit, which is the
 * required gas limit set for the second Teleporter message. The secondaryRequiredGasLimit should be sufficient
 * to cover the destination token operations as well as the call to the recipient contract, and will always be
 * greater than the recipientGasLimit. The multi-hop message also includes the address of the original sender.
 * The source blockchain ID of the sender is known from the Teleporter message.
 */
struct MultiHopCallMessage {
    address originSenderAddress;
    bytes32 destinationBlockchainID;
    address destinationBridgeAddress;
    address recipientContract;
    uint256 amount;
    bytes recipientPayload;
    uint256 recipientGasLimit;
    address fallbackRecipient;
    uint256 secondaryRequiredGasLimit;
    address multiHopFallback;
    uint256 secondaryFee;
}

/**
 * @notice Interface for a Teleporter token bridge that sends tokens to another chain.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
interface ITeleporterTokenBridge is ITeleporterReceiver {
    /**
     * @notice Emitted when tokens are sent to another chain.
     */
    event TokensSent(
        bytes32 indexed teleporterMessageID,
        address indexed sender,
        SendTokensInput input,
        uint256 amount
    );

    /**
     * @notice Emitted when tokens are sent to another chain with calldata for a contract recipient.
     */
    event TokensAndCallSent(
        bytes32 indexed teleporterMessageID,
        address indexed sender,
        SendAndCallInput input,
        uint256 amount
    );

    /**
     * @notice Emitted when tokens are withdrawn from the token bridge contract.
     */
    event TokensWithdrawn(address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when a call to a recipient contract to receive token succeeds.
     */
    event CallSucceeded(address indexed recipientContract, uint256 amount);

    /**
     * @notice Emitted when a call to a recipient contract to receive token fails, and the tokens are sent
     * to a fallback recipient.
     */
    event CallFailed(address indexed recipientContract, uint256 amount);
}
