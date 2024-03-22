// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import {ITeleporterMessenger, TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {ITeleporterReceiver} from "@teleporter/ITeleporterReceiver.sol";
import {TeleporterPromiseOutcome} from "./TeleporterPromiseOutcome.sol";
import {ITeleporterPromiseProcessor} from "./ITeleporterPromiseProcessor.sol";

// contract for promise receiver
contract TeleporterPromiseReceiver {
    ITeleporterMessenger public messenger;
    ITeleporterPromiseProcessor public processor;

    function receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes calldata message)
        external
    {
        try processor.processMessage(sourceBlockchainID, originSenderAddress, message) returns (bytes result) {
            // Successful processing
            this._sendCallback(TeleporterPromiseOutcome.Success, result);
        } catch (bytes memory error) {
            // Failed processing
            this._sendCallback(TeleporterPromiseOutcome.Fail, error);
        }
    }

    function _sendCallback(TeleporterPromiseOutcome outcome, bytes memory resultOrError) internal {
        // Send feedback to the sender
        TeleporterMessageInput memory input;
        // Fill in input parameters for sending the callback
        // ...

        messenger.sendCrossChainMessage(input);
    }
}
