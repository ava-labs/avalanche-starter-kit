// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

enum ProductStatus {
    ACTIVE,
    SOLD,
    PENDING
}

struct IProduct {
    address seller;
    uint256 price;
    ProductStatus status;
    address buyer;
    string title;
    bytes32 sellerBlockchainId;
    uint256 pendingDeadline;
}

struct ICrossChainPaymentResult {
    uint256 productId;
    bool success;
    address buyer;
}

struct ICrossChainPayment {
    address receiverAddress;
    uint256 productId;
    address buyer;
}

struct IProductInput {
    uint256 price;
    string title;
}

struct ICrossChainReceiver {
    address sellerAddress;
    bytes32 sellerBlockchainId;
    uint256 value;
}

enum CommerceMessageType {
    ADD_PRODUCT,
    PURCHASE,
    PAYMENT_RESULT
}

struct ICommerceMessage {
    CommerceMessageType message_type;
    address client;
    bytes payload;
}

struct ITokenSentMessage {
    address buyer;
    uint256 productId;
}

interface IECommerce {}
