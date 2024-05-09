// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @dev Abstract contract that helps implement reentrancy guards for Teleporter token bridge {_send} and {_sendAndCall}
 * functions.
 *
 * The send methods must not allow reentry given that can make calls to external contracts such as {safeTransferFrom}
 * and {safeDeposit}. However, the send methods should be allowed to be called from {receiveTeleporterMessage}, either
 * as a part of processing a multi-hop transfer, or as a part of an external call made to process a "sendAndCall"
 * message.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
abstract contract SendReentrancyGuard {
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 private _sendEntered;

    // sendNonReentrant modifier makes sure there is not reentry between {_send} or {_sendAndCall} calls.
    modifier sendNonReentrant() {
        require(_sendEntered == _NOT_ENTERED, "SendReentrancyGuard: send reentrancy");
        _sendEntered = _ENTERED;
        _;
        _sendEntered = _NOT_ENTERED;
    }

    constructor() {
        _sendEntered = _NOT_ENTERED;
    }
}
