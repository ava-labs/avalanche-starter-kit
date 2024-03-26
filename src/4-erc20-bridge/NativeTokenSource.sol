// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {TeleporterTokenSource} from "./TeleporterTokenSource.sol";
import {INativeTokenBridge} from "./interfaces/INativeTokenBridge.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/utils/SafeERC20.sol";
import {SendTokensInput} from "./interfaces/ITeleporterTokenBridge.sol";
import {IWrappedNativeToken} from "./interfaces/IWrappedNativeToken.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @title NativeTokenSource
 * @notice This contract is an {INativeTokenBridge} that sends native tokens to another chain's
 * {ITeleporterTokenBridge} instance, and gets represented by the tokens of that destination
 * token bridge instance.
 */
contract NativeTokenSource is INativeTokenBridge, TeleporterTokenSource {
    using SafeERC20 for IERC20;

    /**
     * @notice The wrapped native token contract that represents the native tokens on this chain.
     */
    IWrappedNativeToken public immutable token;

    /**
     * @notice Initializes this source token bridge instance
     * @dev Teleporter fees are paid by a {IWrappedNativeToken} instance.
     */
    constructor(
        address teleporterRegistryAddress,
        address teleporterManager,
        address feeTokenAddress
    ) TeleporterTokenSource(teleporterRegistryAddress, teleporterManager, feeTokenAddress) {
        token = IWrappedNativeToken(feeTokenAddress);
    }

    /**
     * @notice Receives native tokens transferred to this contract.
     * @dev This function is called when the token bridge is withdrawing native tokens to
     * transfer to the recipient. The caller must be the wrapped native token contract.
     */
    receive() external payable {
        require(msg.sender == feeTokenAddress, "NativeTokenSource: invalid receive payable sender");
    }

    /**
     * @dev See {INativeTokenBridge-send}
     */
    function send(SendTokensInput calldata input) external payable {
        _send(input, msg.value, false);
    }

    /**
     * @dev See {TeleportTokenSource-_deposit}
     * Deposits the native tokens sent to this contract
     */
    function _deposit(uint256 amount) internal virtual override returns (uint256) {
        token.deposit{value: amount}();
        return amount;
    }

    /**
     * @dev See {TeleportTokenSource-_withdraw}
     * Withdraws the wrapped tokens for native tokens,
     * and sends them to the recipient.
     */
    function _withdraw(address recipient, uint256 amount) internal virtual override {
        token.withdraw(amount);
        payable(recipient).transfer(amount);
    }
}
