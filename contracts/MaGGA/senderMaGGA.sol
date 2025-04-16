// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";

contract SenderOnCChain {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    /**
     * @dev Sends a message to another chain.
     */
    function sendMessage(address destinationAddress, string calldata message) external {
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Replace with blockchainID of your Subnet (see instructions in Readme)
                destinationBlockchainID: 0x02f8b60b4d4070cf62e67802fe6532d4fcfc6582b4048d040ed6cfc7247d86d8,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );
    }
}
