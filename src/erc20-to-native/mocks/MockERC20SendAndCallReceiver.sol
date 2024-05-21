// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {IERC20SendAndCallReceiver} from "../interfaces/IERC20SendAndCallReceiver.sol";
import {SafeERC20TransferFrom} from "@teleporter/SafeERC20TransferFrom.sol";
import {SafeERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice This is mock implementation of {receiveTokens} to be used in tests.
 * This contract DOES NOT provide a mechanism for accessing the tokens transfered to it.
 * Real implementations must ensure that tokens are properly handled and not incorrectly locked.
 */
contract MockERC20SendAndCallReceiver is IERC20SendAndCallReceiver {
    using SafeERC20 for IERC20;

    mapping(bytes32 blockchainID => mapping(address senderAddress => bool blocked)) public
        blockedSenders;

    /**
     * @dev Emitted when receiveTokens is called.
     */
    event TokensReceived(
        bytes32 indexed sourceBlockchainID,
        address indexed originBridgeAddress,
        address indexed originSenderAddress,
        address token,
        uint256 amount,
        bytes payload
    );

    /**
     * @dev See {IERC20SendAndCallReceiver-receiveTokens}
     */
    function receiveTokens(
        bytes32 sourceBlockchainID,
        address originBridgeAddress,
        address originSenderAddress,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        require(
            !blockedSenders[sourceBlockchainID][originSenderAddress],
            "MockERC20SendAndCallReceiver: sender blocked"
        );
        emit TokensReceived({
            sourceBlockchainID: sourceBlockchainID,
            originBridgeAddress: originBridgeAddress,
            originSenderAddress: originSenderAddress,
            token: token,
            amount: amount,
            payload: payload
        });

        require(payload.length > 0, "MockERC20SendAndCallReceiver: empty payload");

        SafeERC20TransferFrom.safeTransferFrom(IERC20(token), amount);
    }

    /**
     * @notice Block a sender from sending tokens to this contract.
     * @param blockchainID The blockchain ID of the sender.
     * @param senderAddress The address of the sender.
     */
    function blockSender(bytes32 blockchainID, address senderAddress) external {
        blockedSenders[blockchainID][senderAddress] = true;
    }
}
