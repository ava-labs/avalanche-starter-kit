// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {IWrappedNativeToken} from "../interfaces/IWrappedNativeToken.sol";

/**
 * @dev Provides a wrapper used for calling the {IWrappedNativeToken-deposit} method
 * to deposit native tokens into the contract.
 *
 * Checks the balance of the contract before and after the call to deposit, and returns the balance
 * increase.
 *
 * Note: A reentrancy guard must always be used when calling token.safeDeposit in order to
 * prevent against possible "before-after" pattern vulnerabilities.
 *
 * @custom:security-contact https://github.com/ava-labs/teleporter-token-bridge/blob/main/SECURITY.md
 */
library SafeWrappedNativeTokenDeposit {
    /**
     * @dev Checks the balance of the contract before and after the call to deposit, and returns the balance
     * increase.
     */
    // solhint-disable private-vars-leading-underscore
    function safeDeposit(IWrappedNativeToken token, uint256 amount) internal returns (uint256) {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.deposit{value: amount}();
        uint256 balanceAfter = token.balanceOf(address(this));

        require(
            balanceAfter > balanceBefore, "SafeWrappedNativeTokenDeposit: balance not increased"
        );

        return balanceAfter - balanceBefore;
    }
    // solhint-enable private-vars-leading-underscore
}
