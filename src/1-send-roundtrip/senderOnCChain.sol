// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract SenderOnCChain is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    string public roundtripMessage;

    /**
     * @dev Sends a message to another chain.
     */
    function sendMessage(address destinationAddress) external {
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Replace with blockchainID of your Subnet (see instructions in Readme)
                destinationBlockchainID: 0x609fa1886e1fbc9585127fa22b6e77a785ebdeecc01049f294638c7909e53c5e,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode("Hello")
            })
        );
    }

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(messenger), "SenderOnCChain: unauthorized TeleporterMessenger");

        // Store the message.
        roundtripMessage = abi.decode(message, (string));
    }
}
