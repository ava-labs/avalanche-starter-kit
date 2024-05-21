// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {
    ITeleporterTokenBridge, SendTokensInput, SendAndCallInput
} from "./ITeleporterTokenBridge.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice Interface for a Teleporter token bridge that sends ERC20 tokens to another chain.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
interface IERC20Bridge is ITeleporterTokenBridge {
    /**
     * @notice Sends ERC20 tokens transferred to this contract to the destination token bridge instance.
     * @param input Specifies information for delivery of the tokens
     * @param amount Amount of tokens to send
     */
    function send(SendTokensInput calldata input, uint256 amount) external;

    /**
     * @notice Sends ERC20 tokens transferred to this contract to the destination token bridge instance.
     * @param input Specifies information for delivery of the tokens
     * @param amount Amount of tokens to send
     */
    function sendAndCall(SendAndCallInput calldata input, uint256 amount) external;
}
