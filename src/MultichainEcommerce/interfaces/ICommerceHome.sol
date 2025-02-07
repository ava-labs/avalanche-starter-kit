// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

import {IProductInput, IProduct} from "./IECommerce.sol";

interface ICommerceHome {
    //This event refer the successfully buying a product and this data will be processing the front-end app
    event ProductsBuy(
        uint256 indexed productId,
        address indexed buyer,
        uint256 price,
        address indexed seller,
        bytes32 sellerBlockchainID
    );

    //This event refer the successfully adding a product and this data will be processing the front-end app
    event ProductAdded(uint256 indexed productId, address indexed sender);

    event PaymentSuccessful(
        uint256 indexed productId, address indexed buyer, bytes32 sellerBlockchainId, address indexed seller
    );
    event PaymentFailed(uint256 indexed productId, address indexed buyer);

    function addProduct(IProductInput memory _product) external;

    //For checking active remotes
    //currently it only operates on 1 remote, but it will be more useful when more chain support comes in the future :)

    function activeRemoteAddress(bytes32 remote) external view returns (address);

    //This function is used to get the details of the requested product id
    function getProduct(uint256 id) external view returns (IProduct memory product);

    //Gets all products added by the user whose address is entered (including inactive ones)
    function getSellerToProducts(address seller) external view returns (uint256[] memory);
}
