// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract SimpleCalculatorReceiverOnSubnet is ITeleporterReceiver {
    ITeleporterMessenger public immutable teleporterMessenger =
        ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    uint256 public result_num;

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        // Only the Teleporter receiver can deliver a message.
        require(
            msg.sender == address(teleporterMessenger), "CalculatorReceiverOnSubnet: unauthorized TeleporterMessenger"
        );

        (uint256 a, uint256 b) = abi.decode(message, (uint256, uint256));
        _calculatorAdd(a, b);
    }

    function _calculatorAdd(uint256 _num1, uint256 _num2) internal {
        result_num = _num1 + _num2;
    }
}
