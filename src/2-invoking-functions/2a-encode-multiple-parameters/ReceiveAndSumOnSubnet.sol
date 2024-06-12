// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract ReceiveAndSumOnDestination is ITeleporterReceiver {
    
    ITeleporterMessenger public immutable teleporterMessenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    uint256 public result;


    /**
     * @dev See {ITeleporterReceiver-receiveTeleporterMessage}.
     *
     * Receives a message from another chain.
     */
    function receiveTeleporterMessage(
      bytes32 originChainID,
      address originSenderAddress,
      bytes calldata message
    ) external {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(teleporterMessenger), "ReceiveNumbersAndSumOnDispatch: unauthorized TeleporterMessenger");

        // Decoding the function parameters
        (
            uint256 num1,
            uint256 num2
        ) = abi.decode(message, (uint256, uint256));

        _sum(num1,num2);
    }

    function _sum(uint256 _num1, uint256 _num2) private {
        // Calling the internal function
        result = _num1+_num2;
    }
}