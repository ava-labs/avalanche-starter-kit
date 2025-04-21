// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";

contract ReceiverWinner is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);
    address private winner;

    event WinnerUpdated(address newWinner);

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        require(msg.sender == address(messenger), "Unauthorized TeleporterMessenger");

        address newWinner = abi.decode(message, (address));
        winner = newWinner;
        emit WinnerUpdated(newWinner);
    }

    function viewWinner() public view returns (address) {
        return winner;
    }
}