// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";

import "@teleporter/ITeleporterReceiver.sol";

contract CalculatorReceiverOnCChain is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    uint256 public lastResult;
    uint256 public num1Received;
    uint256 public num2Received;

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        require(msg.sender == address(messenger), "Unauthorized");

        (uint256 num1, uint256 num2) = abi.decode(message, (uint256, uint256));
        num1Received = num1;
        num2Received = num2;
        lastResult = num1 + num2;
    }

    function getResult() external view returns (uint256) {
        return lastResult;
    }
}
