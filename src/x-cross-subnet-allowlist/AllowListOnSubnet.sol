// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract AllowListOnSubnet is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    mapping(address => bool) allowlist;

    function allow(address a) public {
        allowlist[a] = true;
    }

    function receiveTeleporterMessage(bytes32, address originSenderAddress, bytes calldata message) external {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(messenger), "ReceiverOnSubnet: unauthorized TeleporterMessenger");

        // Check if the origin sender is allowed
        require(allowlist[originSenderAddress], "ReceiverOnSubnet: sender not on the allowlist");

        // Send Roundtrip message back to sender
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Blockchain ID of C-Chain
                destinationBlockchainID: 0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5,
                destinationAddress: originSenderAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: message
            })
        );
    }
}
