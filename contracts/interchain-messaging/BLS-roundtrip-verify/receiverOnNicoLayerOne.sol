// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract ReceiverOnNicoLayerOne is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    function receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes calldata message)
        external
    {
        // Only the TeleporterMessenger can deliver a message.
        require(msg.sender == address(messenger), "ReceiverOnNicoLayerOne: unauthorized TeleporterMessenger");

        // Decode the message. Use 'memory' since abi.decode returns memory types.
        (string memory messageValue, bytes memory signature, bytes memory publicKey) =
            abi.decode(message, (string, bytes, bytes));

        // Dummy verification: use verifyBLS which now accepts memory parameters.
        bool verificationResult = verifyBLS(messageValue, signature, publicKey);

        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Use the source blockchain ID for the destination.
                destinationBlockchainID: sourceBlockchainID,
                destinationAddress: originSenderAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(verificationResult)
            })
        );
    }

    function verifyBLS(string memory messageValue, bytes memory signature, bytes memory publicKey)
        internal
        view
        returns (bool)
    {
        // Not good to dictate outcomes based on block timestamp,
        // just done to alternate the value for testing.
        if (bytes(messageValue).length > 0 && signature.length > 0 && publicKey.length > 0 && block.timestamp % 2 == 0)
        {
            return true;
        }
        return false;
    }
}
