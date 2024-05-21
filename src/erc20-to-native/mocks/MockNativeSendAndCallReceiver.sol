// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {INativeSendAndCallReceiver} from "../interfaces/INativeSendAndCallReceiver.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice This is mock implementation of {receiveTokens} to be used in tests.
 * This contract DOES NOT provide a mechanism for accessing the tokens transfered to it.
 * Real implementations must ensure that tokens are properly handled and not incorrectly locked.
 */
contract MockNativeSendAndCallReceiver is INativeSendAndCallReceiver {
    mapping(bytes32 blockchainID => mapping(address senderAddress => bool blocked)) public
        blockedSenders;

    /**
     * @dev Emitted when receiveTokens is called.
     */
    event TokensReceived(
        bytes32 indexed sourceBlockchainID,
        address indexed originBridgeAddress,
        address indexed originSenderAddress,
        uint256 amount,
        bytes payload
    );

    /**
     * @dev See {INativeSendAndCallReceiver-receiveTokens}
     */
    function receiveTokens(
        bytes32 sourceBlockchainID,
        address originBridgeAddress,
        address originSenderAddress,
        bytes calldata payload
    ) external payable {
        require(
            !blockedSenders[sourceBlockchainID][originSenderAddress],
            "MockNativeSendAndCallReceiver: sender blocked"
        );
        emit TokensReceived(
            sourceBlockchainID, originBridgeAddress, originSenderAddress, msg.value, payload
        );

        require(payload.length != 0, "MockNativeSendAndCallReceiver: empty payload");
        // No implementation required to accept native tokens
    }

    /**
     * @notice Block a sender from sending tokens to this contract.
     * @param blockchainID The blockchain ID of the sender.
     * @param senderAddress The address of the sender.
     */
    function blockSender(bytes32 blockchainID, address senderAddress) external {
        blockedSenders[blockchainID][senderAddress] = true;
    }
}
