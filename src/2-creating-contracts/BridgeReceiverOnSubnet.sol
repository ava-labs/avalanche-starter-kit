// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";
import "./MyERC20Token.sol";
import "./BridgeActions.sol";

contract TokenMinterReceiverOnBulletin is ITeleporterReceiver {
    ITeleporterMessenger public immutable teleporterMessenger =
        ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);
    address public tokenAddress;

    // Errors
    error Unauthorized();

    function receiveTeleporterMessage(bytes32 originChainID, address originSenderAddress, bytes calldata message)
        external
    {
        // Only the Teleporter receiver can deliver a message.
        if (msg.sender != address(teleporterMessenger)) {
            revert Unauthorized();
        }

        // Decoding the Action type:
        (BridgeAction actionType, bytes memory paramsData) = abi.decode(message, (BridgeAction, bytes));

        // Route to the appropriate function.
        if (actionType == BridgeAction.createToken) {
            (string memory name, string memory symbol) = abi.decode(paramsData, (string, string));
            tokenAddress = address(new myToken(name, symbol));
        } else if (actionType == BridgeAction.mintToken) {
            (address recipient, uint256 amount) = abi.decode(paramsData, (address, uint256));
            myToken(tokenAddress).mint(recipient, amount);
        } else {
            revert("Receiver: invalid action");
        }
    }
}
