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
 * @dev Interface for a "home" or "source" bridge contract that locks
 * tokens on its chain to be bridge to supported destination bridge contracts on other chains.
 */
interface ITeleporterTokenSource is ITeleporterTokenBridge {
    /**
     * @dev Emitted when tokens are added as collateral for a destination bridge.
     * The event emits a {remaining} value of 0 when the destination bridge is fully collateralized.
     */
    event CollateralAdded(
        bytes32 indexed destinationBlockchainID,
        address indexed destinationBridgeAddress,
        uint256 amount,
        uint256 remaining
    );

    /**
     * @notice Emitted when a destination is registered with the token bridge.
     */
    event DestinationRegistered(
        bytes32 indexed destinationBlockchainID,
        address indexed destinationBridgeAddress,
        uint256 initialCollateralNeeded,
        uint256 tokenMultiplier,
        bool multiplyOnDestination
    );

    /**
     * @notice Emitted when tokens are routed from a multi-hop send message to another chain.
     */
    event TokensRouted(bytes32 indexed teleporterMessageID, SendTokensInput input, uint256 amount);

    /**
     * @notice Emitted when tokens are routed from a mulit-hop send message,
     * with calldata for a contract recipient, to another chain.
     */
    event TokensAndCallRouted(
        bytes32 indexed teleporterMessageID, SendAndCallInput input, uint256 amount
    );
}
