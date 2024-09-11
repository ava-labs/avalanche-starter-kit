// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/IERC20.sol";

contract SenderWithFeesOnCChain {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);
    /**
     * @dev Sends a message to another chain.
     */

    function sendMessage(address destinationAddress, string calldata message, address feeAddress) external {
        IERC20 feeContract = IERC20(feeAddress);
        uint256 feeAmount = 500000000000000;
        feeContract.transferFrom(msg.sender, address(this), feeAmount);
        feeContract.approve(address(messenger), feeAmount);

        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Replace with blockchainID of your Subnet (see instructions in Readme)
                destinationBlockchainID: 0x52f2c4d51ef13a5781babe42c1b916e98fc88fc72919b20527782c939c8be71d,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: feeAddress, amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );
    }
}
