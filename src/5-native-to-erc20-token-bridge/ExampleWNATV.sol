// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {IWrappedNativeToken} from "@teleporter-token-bridge/interfaces/IWrappedNativeToken.sol";
import {ERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";
import {Address} from "@openzeppelin/contracts@4.8.1/utils/Address.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract WNATV is IWrappedNativeToken, ERC20 {
    using Address for address payable;

    constructor() ERC20("Wrapped NATV", "WNATV") {}

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
        payable(msg.sender).sendValue(amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }
}
