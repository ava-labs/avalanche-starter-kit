// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {ITeleporterTokenBridge} from "./ITeleporterTokenBridge.sol";
import {TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice Settings for constructing a {ITeleporterTokenDestination} contract.
 * @param teleporterRegistryAddress The current blockchain ID's Teleporter registry
 * address. See here for details: https://github.com/ava-labs/teleporter/tree/main/contracts/src/Teleporter/upgrades.
 * @param teleporterManager Address that manages this contract's integration with the
 * Teleporter registry and Teleporter versions.
 * @param sourceBlockchainID The blockchain ID of the associated source token bridge
 * @param tokenSourceAddress The address of the source token bridge contract.
 */
struct TeleporterTokenDestinationSettings {
    address teleporterRegistryAddress;
    address teleporterManager;
    bytes32 sourceBlockchainID;
    address tokenSourceAddress;
}

/**
 * @dev Interface for a destination bridge contract that mints a representation token on its chain, and allows
 * for burning that token to redeem the backing asset on the source chain, or briding to other destinations.
 */
interface ITeleporterTokenDestination is ITeleporterTokenBridge {
    /**
     * @notice Sends a Teleporter message to register the destination instance with its configured source.
     * @param feeInfo The fee asset and amount for the Teleporter message
     */
    function registerWithSource(TeleporterFeeInfo calldata feeInfo) external;
}
