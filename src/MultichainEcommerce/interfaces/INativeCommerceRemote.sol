// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

import {ICommerceRemote} from "./ICommerceRemote.sol";

interface INativeCommerceRemote is ICommerceRemote {
    function crossChainBuyProduct(uint256 productId) external payable;
}
