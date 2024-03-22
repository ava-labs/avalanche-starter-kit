// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import {ITeleporterMessenger, TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {ITeleporterReceiver} from "@teleporter/ITeleporterReceiver.sol";
import {TeleporterPromiseOutcome} from "./TeleporterPromiseOutcome.sol";

// Abstract contract for promise sender
abstract contract TeleporterPromiseSender is ITeleporterReceiver {
    function thenCallback(bytes32 messageId, bytes memory result) external virtual;
    function catchCallback(bytes32 messageId, bytes memory error) external virtual;

    function receiveTeleporterMessage(bytes32 messageId, bytes calldata message) external override {
        // Unpack message and call thenCallback or catchCallback
        (TeleporterPromiseOutcome outcome, bytes memory data) = abi.decode(message, (TeleporterPromiseOutcome, bytes));
        if (outcome == TeleporterPromiseOutcome.Success) {
            thenCallback(messageId, data);
        } else {
            catchCallback(messageId, data);
        }
    }
}
