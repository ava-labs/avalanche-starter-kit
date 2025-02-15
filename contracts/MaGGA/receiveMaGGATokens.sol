// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";
import "./createToken.sol";

contract ReceiveMaGGATokens is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);
    MyToken public tokenNetwork;
    uint public lastAmount;
    address public receiver;
    constructor(address token, address _receiver) {
        tokenNetwork = new MyToken(token);
        receiver = _receiver;
    }
    function receiveTeleporterMessage(bytes32, address, uint calldata amount) external {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(messenger), "ReceiverOnSubnet: unauthorized TeleporterMessenger");

        // Store the message.
        lastAmount = abi.decode(amount, (uint));
        tokenNetwork.mint(receiver, lastAmount);

    }
}
