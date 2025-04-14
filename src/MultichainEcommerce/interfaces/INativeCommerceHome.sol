// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

import {IProductInput, ProductStatus} from "./IEcommerce.sol";
import {ICommerceHome} from "./ICommerceHome.sol";

interface INativeCommerceHome is ICommerceHome {
    function buyProduct(uint256 _productId) external payable;
}
