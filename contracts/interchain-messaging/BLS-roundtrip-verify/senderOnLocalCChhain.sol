// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract SenderOnLocalCChain is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    bool public verificationResult;

    function sendMessage(
        address destinationAddress,
        string calldata message,
        bytes calldata signature,
        bytes calldata publicKey
    ) external {
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // blockchainID of Nico layer 1
                destinationBlockchainID: 0x5a5a8cd30d69c017c454fbadd0c0ebc6c763b0017070b7a38aa227cd616ecc34,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message, signature, publicKey)
            })
        );
    }

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(messenger), "SenderOnCChain: unauthorized TeleporterMessenger");

        // Store the message.
        bool result = abi.decode(message, (bool));
        verificationResult = result;
    }
}
