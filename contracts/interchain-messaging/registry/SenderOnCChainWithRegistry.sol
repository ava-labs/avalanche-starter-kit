// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/upgrades/TeleporterRegistry.sol";
import "@teleporter/ITeleporterMessenger.sol";

contract SenderOnCChain {
    // The Teleporter registry contract manages different Teleporter contract versions.
    TeleporterRegistry public immutable teleporterRegistry =
        TeleporterRegistry(0xF86Cb19Ad8405AEFa7d09C778215D2Cb6eBfB228);

    /**
     * @dev Sends a message to another chain.
     */
    function sendMessage(address destinationAddress, string calldata message) external {
        ITeleporterMessenger messenger = teleporterRegistry.getLatestTeleporter();

        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // BlockchainID of Dispatch L1
                destinationBlockchainID: 0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );
    }
}
