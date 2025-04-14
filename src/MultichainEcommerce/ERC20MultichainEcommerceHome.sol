// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

import {SendAndCallInput} from "@avalanche-interchain-token-transfer/interfaces/ITokenBridge.sol";
import {IERC20TokenBridge} from "@avalanche-interchain-token-transfer/interfaces/IERC20TokenBridge.sol";
import {IERC20CommerceHome} from "./interfaces/IERC20CommerceHome.sol";
import {
    IProduct,
    CommerceMessageType,
    ICommerceMessage,
    ICrossChainPayment,
    ITokenSentMessage,
    ICrossChainPaymentResult,
    IProductInput,
    ProductStatus
} from "./interfaces/IECommerce.sol";
import {TeleporterOwnerUpgradeable} from "@teleporter/upgrades/TeleporterOwnerUpgradeable.sol";
import {IERC20SendAndCallReceiver} from "@avalanche-interchain-token-transfer/interfaces/IERC20SendAndCallReceiver.sol";
import {SafeERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";

contract ERC20MultichainEcommerceHome is IERC20CommerceHome, TeleporterOwnerUpgradeable, IERC20SendAndCallReceiver {
    using SafeERC20 for IERC20;

    IERC20TokenBridge ERC20TokenTransferrer;
    IERC20 ERC20TOKEN;
    mapping(uint256 => IProduct) public products;
    mapping(address => uint256[]) public sellerToProducts;
    mapping(bytes32 => address) public activeRemotes;
    mapping(bytes32 => address) public activeTokenTransferrer;
    bytes32 public remoteBlockchainID;
    bytes32 public homeBlockchainId;
    uint256 public constant MIN_AMOUNT = 10 ** 6;
    uint256 public lastProductId = 0;
    bytes32 homeTokenTransferrerBlockchainID;

    constructor(
        address teleporterRegistryAddress,
        address initialOwner,
        address ERC20TokenTransferrer_,
        bytes32 homeBlockchainId_,
        bytes32 remoteBlockchainID_,
        address erc20Address_,
        bytes32 homeTokenTransferrerBlockchainID_
    ) TeleporterOwnerUpgradeable(teleporterRegistryAddress, initialOwner) {
        ERC20TokenTransferrer = IERC20TokenBridge(ERC20TokenTransferrer_);

        homeBlockchainId = homeBlockchainId_;
        activeRemotes[homeBlockchainId_] = ERC20TokenTransferrer_;
        remoteBlockchainID = remoteBlockchainID_;
        ERC20TOKEN = IERC20(erc20Address_);
        homeTokenTransferrerBlockchainID = homeTokenTransferrerBlockchainID_;
    }

    //this function only callable from e-commerce remote.
    //make sure the remote contract is secure. otherwise if payments failed then fund trasfer wrong address.
    //ICTT bridge and _buyProduct already protected against reentrancy attack, so no need to check it again.
    // payload type is struct ITokenSentMessage (address buyer,uint256[] productIds) decode and call standard buying procces

    function receiveTokens(
        bytes32 sourceBlockchainID,
        address originTokenTransferrerAddress,
        address originSenderAddress,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        require(msg.sender == address(ERC20TokenTransferrer), "not authorize");
        require(originTokenTransferrerAddress == activeTokenTransferrer[sourceBlockchainID], "not authorize");
        require(originSenderAddress == activeRemotes[sourceBlockchainID]);
        ITokenSentMessage memory message = abi.decode(payload, (ITokenSentMessage));
        require(token == address(ERC20TOKEN), "invalid token");
        ERC20TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        _buyProduct(message.productId, message.buyer, amount);
    }

    //this function allows the owner to authorize active remote contracts.
    //remote address should be the address on the chain given the blockhain id.
    function _setActiveRemote(address remoteaddr, bytes32 chainID, address remoteTokenTransferrerAddress)
        external
        onlyOwner
    {
        activeRemotes[chainID] = remoteaddr;
        activeTokenTransferrer[chainID] = remoteTokenTransferrerAddress;
    }
    //used for receptions in the same chain Since the called function is specified as nonReentrant, it does not need to be specified as nonReentrant again

    function buyProduct(uint256 _productId, uint256 amount) public {
        ERC20TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        address _buyer = msg.sender;
        require(amount >= MIN_AMOUNT, "payment is too low");
        _buyProduct(_productId, _buyer, amount);
    }
    //This function allows the user to add one or more products.

    function addProduct(IProductInput memory _product) public {
        IProductInput memory input = _product;
        IProduct memory created = IProduct({
            seller: msg.sender,
            price: input.price,
            status: ProductStatus.ACTIVE,
            buyer: address(0),
            title: input.title,
            sellerBlockchainId: homeBlockchainId,
            pendingDeadline: 0
        });
        _addProduct(created, msg.sender);
    }

    function activeRemoteAddress(bytes32 remote) public view returns (address) {
        address remoteECommerce = activeRemotes[remote];
        return remoteECommerce;
    }

    function getProduct(uint256 id) public view returns (IProduct memory product) {
        return (products[id]);
    }

    function getProductStatus(uint256 productId) public view returns (ProductStatus) {
        return (products[productId].status);
    }

    function getSellerToProducts(address seller) public view returns (uint256[] memory) {
        uint256[] memory userProducts = sellerToProducts[seller];
        return userProducts;
    }
    // for cross chain  products handle

    function crosschainAddProduct(IProductInput memory _product, bytes32 blockchainId, address client) internal {
        require(activeRemotes[blockchainId] != address(0), "chain is not registered");
        IProductInput memory input = _product;
        IProduct memory created = IProduct({
            seller: client,
            price: input.price,
            status: ProductStatus.ACTIVE,
            buyer: address(0),
            title: input.title,
            sellerBlockchainId: blockchainId,
            pendingDeadline: 0
        });
        _addProduct(created, client);
    }

    function _addProduct(IProduct memory _product, address _sender) internal {
        uint256 addedProductId = lastProductId;
        lastProductId++;
        address sender = _sender;
        require(sender != address(0), "invalid address");
        require(products[addedProductId].seller == address(0), "already claimed id");
        require(_product.price >= MIN_AMOUNT, "price is too low");
        products[addedProductId] = _product;
        sellerToProducts[sender].push(addedProductId);
        emit ProductAdded(addedProductId, _sender);
    }

    function _buyProduct(uint256 _product, address _buyer, uint256 amount) internal nonReentrant {
        IProduct memory selected = products[_product];
        require(_product <= lastProductId, "product not found");
        require(selected.price <= amount);
        require(activeRemotes[selected.sellerBlockchainId] != address(0), "chain is not registered");
        require(selected.status == ProductStatus.ACTIVE, "product not active");
        products[_product].buyer = _buyer;
        if (selected.sellerBlockchainId != homeBlockchainId) {
            ICrossChainPayment memory payment =
                ICrossChainPayment({receiverAddress: selected.seller, productId: _product, buyer: _buyer});
            sendCrossChainPayment(payment, _buyer, selected.price, selected.sellerBlockchainId);
            products[_product].status = ProductStatus.PENDING;
            products[_product].pendingDeadline = block.timestamp + 1 hours;
            products[_product].buyer = _buyer;
            emit ProductsBuy(_product, _buyer, selected.price, selected.seller, selected.sellerBlockchainId);
        } else {
            selected.status = ProductStatus.SOLD;
            ERC20TOKEN.safeTransfer(selected.seller, selected.price);
            emit ProductsBuy(_product, _buyer, selected.price, selected.seller, selected.sellerBlockchainId);
            emit PaymentSuccessful(_product, _buyer, selected.sellerBlockchainId, selected.seller);
        }
    }

    function sendCrossChainPayment(
        ICrossChainPayment memory payment,
        address buyer,
        uint256 value,
        bytes32 sellerBlockchainId
    ) internal {
        bool isSingleHop = (
            (homeBlockchainId == homeTokenTransferrerBlockchainID)
                || (sellerBlockchainId == homeTokenTransferrerBlockchainID)
        );
        ERC20TokenTransferrer.sendAndCall(
            SendAndCallInput({
                destinationBlockchainID: remoteBlockchainID,
                destinationBridgeAddress: activeTokenTransferrer[sellerBlockchainId],
                recipientContract: activeRemotes[sellerBlockchainId],
                recipientPayload: abi.encode(payment),
                requiredGasLimit: 500_000,
                recipientGasLimit: 350_000,
                multiHopFallback: isSingleHop ? address(0) : buyer,
                fallbackRecipient: buyer,
                primaryFeeTokenAddress: activeTokenTransferrer[sellerBlockchainId],
                primaryFee: 0,
                secondaryFee: 0
            }),
            value
        );
    }

    function _receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes memory message)
        internal
        override
    {
        require(activeRemotes[sourceBlockchainID] == originSenderAddress, "remote not registered");
        ICommerceMessage memory payload = abi.decode(message, (ICommerceMessage));
        if (payload.message_type == CommerceMessageType.ADD_PRODUCT) {
            IProductInput memory productDetails = abi.decode(payload.payload, (IProductInput));
            crosschainAddProduct(productDetails, sourceBlockchainID, payload.client);
        } else if (payload.message_type == CommerceMessageType.PAYMENT_RESULT) {
            ICrossChainPaymentResult memory result = abi.decode(payload.payload, (ICrossChainPaymentResult));
            if (result.success) {
                require(products[result.productId].status == ProductStatus.PENDING, "product is not buying proccess");
                products[result.productId].status = ProductStatus.SOLD;
                emit PaymentSuccessful(result.productId, result.buyer, sourceBlockchainID, payload.client);
                products[result.productId].buyer = result.buyer;
            } else {
                require(products[result.productId].status == ProductStatus.PENDING, "product is not buying proccess");
                products[result.productId].status = ProductStatus.ACTIVE;
                products[result.productId].buyer = address(0);
                emit PaymentFailed(result.productId, result.buyer);
            }
        }
    }
}
