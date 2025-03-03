// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

import {ICommerceRemote} from "./ICommerceRemote.sol";

interface IERC20CommerceRemote is ICommerceRemote {
    function crossChainBuyProduct(uint256 productId, uint256 value) external;
}
