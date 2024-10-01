// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IWAVAX {
    function withdraw(uint256 amount) external;

    function deposit() external payable;
}
