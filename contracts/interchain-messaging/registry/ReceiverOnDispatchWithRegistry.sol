// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/upgrades/TeleporterRegistry.sol";
import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract ReceiverOnDispatchWithRegistry is ITeleporterReceiver {
    // The Teleporter registry contract manages different Teleporter contract versions.
    TeleporterRegistry public immutable teleporterRegistry =
        TeleporterRegistry(0x827364Da64e8f8466c23520d81731e94c8DDe510);

    string public lastMessage;

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        // Only a Teleporter Messenger registered in the registry can deliver a message.
        // Function throws an error if msg.sender is not registered.
        teleporterRegistry.getVersionFromAddress(msg.sender);

        // Store the message.
        lastMessage = abi.decode(message, (string));
    }
}
