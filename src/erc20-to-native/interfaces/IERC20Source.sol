// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {IERC20Bridge} from "./IERC20Bridge.sol";
import {ITeleporterTokenSource} from "./ITeleporterTokenSource.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice Interface for a "home" or "source" ERC20 bridge contract that locks
 * tokens on its chain to be bridged to supported destination bridge contracts on other chains.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
interface IERC20Source is IERC20Bridge, ITeleporterTokenSource {
    /**
     * @notice Adds collateral to the bridge contract for the specified destination. If more value is provided
     * than the amount of collateral needed, the excess amount is returned to the caller.
     * @param destinationBlockchainID The destination blockchain ID of the bridge to add collateral for.
     * @param destinationBridgeAddress The address of the bridge to add collateral for on the {destinationBlockchainID}.
     * @param amount Amount of tokens to add as collateral.
     */
    function addCollateral(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        uint256 amount
    ) external;
}
