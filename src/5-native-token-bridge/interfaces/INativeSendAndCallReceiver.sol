// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice Interface for a contracts that are called to receive native tokens.
 */
interface INativeSendAndCallReceiver {
    /**
     * @notice Called to receive the amount of the native token. Implementations
     * must properly handle the msg.value of the call in order to ensure it doesn't
     * become improperly made inaccessible.
     * @param sourceBlockchainID blockchain ID that the transfer originated from
     * @param originSenderAddress address of the sender that sent the transfer
     * @param payload arbitrary data provided by the caller
     */
    function receiveTokens(bytes32 sourceBlockchainID, address originSenderAddress, bytes calldata payload)
        external
        payable;
}
