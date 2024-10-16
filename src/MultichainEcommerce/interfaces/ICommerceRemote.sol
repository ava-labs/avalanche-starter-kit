// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

interface ICommerceRemote {
    event crossChainProductAdded(address seller);
    event crossChainProductBuy(address buyer, uint256 indexed productId);
    event crossChainPaymentReceived(address receiver, address buyer, uint256 productId);
    event crossChainPaymentFailed(address receiver, address buyer, uint256 productId);

    function crossChainAddProduct(uint256 price, string memory title) external;
}
