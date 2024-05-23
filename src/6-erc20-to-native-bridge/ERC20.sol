// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^ 0.8.18;

import "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";

/* this is an example ERC20 token called BOK */

contract BOK is ERC20 {
    constructor() ERC20("BOK", "BOK") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}