// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

import {ICommerceHome} from "./ICommerceHome.sol";

interface IERC20CommerceHome is ICommerceHome {
    //Buy product with home chain
    //@Params _product refer the client product input
    function buyProduct(uint256 _productId, uint256 amount) external;
}
