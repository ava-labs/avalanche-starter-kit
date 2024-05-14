// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {INativeTokenBridge} from "./INativeTokenBridge.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @dev Interface that describes functionalities for a contract that can mint native tokens when
 * paired with a {INativeTokenSource} or {IERC20TokenSource} contract that will lock tokens on another chain.
 */
interface INativeTokenDestination is INativeTokenBridge {
    /**
     * @dev Emitted when tokens are not minted in order to collateralize the source contract.
     */
    event CollateralAdded(uint256 amount, uint256 remaining);

    /**
     * @dev Emitted when reporting burned tx fees to source chain.
     */
    event ReportBurnedTxFees(bytes32 indexed teleporterMessageID, uint256 feesBurned);

    /**
     * @dev Returns true if the reserve imbalance for this contract has been accounted for.
     *  When this is true, all tokens sent to this chain will be minted, and sending tokens
     *  to the source chain is allowed.
     */
    function isCollateralized() external view returns (bool);

    /**
     * @dev Returns a best-estimate (upper bound) of the supply of the native asset
     * in circulation on this chain. Does not account for other native asset burn mechanisms,
     * which can result in the value returned being greater than true circulating supply.
     */
    function totalNativeAssetSupply() external view returns (uint256);
}
