// SPDX-License-Identifier: Ecosystem
pragma solidity ^ 0.8.18;

import {TeleporterOwnerUpgradeable} from "@teleporter/upgrades/TeleporterOwnerUpgradeable.sol";
import {
    CommerceMessageType,
    ICommerceMessage,
    ICrossChainPayment,
    ITokenSentMessage,
    ICrossChainPaymentResult,
    IProductInput
} from "./interfaces/IECommerce.sol";
import {IERC20CommerceRemote} from "./interfaces/IERC20CommerceRemote.sol";
import {IERC20SendAndCallReceiver} from "@avalanche-interchain-token-transfer/interfaces/IERC20SendAndCallReceiver.sol";
import {IERC20TokenBridge} from "@avalanche-interchain-token-transfer/interfaces/IERC20TokenBridge.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/utils/SafeERC20.sol";
import {TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {SendAndCallInput} from "@avalanche-interchain-token-transfer/interfaces/ITokenBridge.sol";

contract ERC20MultichainEcommerceRemote is
    IERC20CommerceRemote,
    TeleporterOwnerUpgradeable,
    IERC20SendAndCallReceiver
{
    using SafeERC20 for IERC20;

    IERC20 public ERC20Token;
    IERC20TokenBridge public ERC20TokenTransferrer;
    address public eCommerceHomeTokenTransferrer;
    bytes32 public eCommerceHomeblockchainId;
    address public homeAddress;
    bytes32 public homeTokenTransferrerBlockchainID;
    bytes32 public blockchainId;

    constructor(
        address teleporterRegistryAddress,
        address initialOwner,
        address ERC20TokenTransferrer_,
        address eCommerceHomeTokenTransferrer_,
        bytes32 eCommerceHomeblockchainId_,
        address homeAddress_,
        address erc20Address_,
        bytes32 homeTokenTransferrerBlockchainID_,
        bytes32 blockchainId_
    ) TeleporterOwnerUpgradeable(teleporterRegistryAddress, initialOwner) {
        ERC20TokenTransferrer = IERC20TokenBridge(ERC20TokenTransferrer_);
        eCommerceHomeTokenTransferrer = eCommerceHomeTokenTransferrer_;
        eCommerceHomeblockchainId = eCommerceHomeblockchainId_;
        homeAddress = homeAddress_;
        homeTokenTransferrerBlockchainID = homeTokenTransferrerBlockchainID_;
        ERC20Token = IERC20(erc20Address_);
        blockchainId = blockchainId_;
    }

    function receiveTokens(
        bytes32 sourceBlockchainID,
        address originTokenTransferrerAddress,
        address originSenderAddress,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        require(sourceBlockchainID == eCommerceHomeblockchainId, "only home");
        require(originTokenTransferrerAddress == eCommerceHomeTokenTransferrer, "only home");
        require(originSenderAddress == address(homeAddress), "only home");
        IERC20 Token = IERC20(token);

        Token.transferFrom(msg.sender, address(this), amount);
        ICrossChainPayment memory payment = abi.decode(payload, (ICrossChainPayment));

        if (payment.receiverAddress == address(0)) {
            emit crossChainPaymentFailed(payment.receiverAddress, payment.buyer, payment.productId);
            _sendToFallbackReceiver(payment.buyer, amount);
            ICrossChainPaymentResult memory paymentsReceipt =
                ICrossChainPaymentResult({productId: payment.productId, success: false, buyer: payment.buyer});

            sendResultToHome(paymentsReceipt, payment.buyer);
        }
        (bool success,) = address(Token).call(abi.encodeCall(Token.transfer, (payment.receiverAddress, amount)));
        if (success) {
            emit crossChainPaymentReceived(payment.receiverAddress, payment.buyer, payment.productId);

            ICrossChainPaymentResult memory paymentsReceipt =
                ICrossChainPaymentResult({productId: payment.productId, success: true, buyer: payment.buyer});
            sendResultToHome(paymentsReceipt, payment.buyer);
        } else {
            emit crossChainPaymentFailed(payment.receiverAddress, payment.buyer, payment.productId);

            ICrossChainPaymentResult memory paymentsReceipt =
                ICrossChainPaymentResult({productId: payment.productId, success: false, buyer: payment.buyer});

            _sendToFallbackReceiver(payment.buyer, amount);
            sendResultToHome(paymentsReceipt, payment.buyer);
        }
    }

    function crossChainBuyProduct(uint256 productId, uint256 value) public {
        ERC20Token.safeTransferFrom(msg.sender, address(this), value);
        ERC20Token.safeIncreaseAllowance(address(ERC20TokenTransferrer), value);
        bool isSingleHop = (
            (eCommerceHomeblockchainId == homeTokenTransferrerBlockchainID)
                || (blockchainId == homeTokenTransferrerBlockchainID)
        );
        ERC20TokenTransferrer.sendAndCall(
            SendAndCallInput({
                destinationBlockchainID: eCommerceHomeblockchainId,
                destinationBridgeAddress: eCommerceHomeTokenTransferrer,
                recipientContract: address(homeAddress),
                recipientPayload: abi.encode(ITokenSentMessage({buyer: msg.sender, productId: productId})),
                requiredGasLimit: 900_000,
                recipientGasLimit: 700_000,
                multiHopFallback: isSingleHop ? address(0) : msg.sender,
                fallbackRecipient: msg.sender,
                primaryFeeTokenAddress: address(ERC20Token),
                primaryFee: 0,
                secondaryFee: 0
            }),
            value
        );
        ERC20Token.safeApprove(address(ERC20TokenTransferrer), 0);
        emit crossChainProductBuy(msg.sender, value);
    }

    function crossChainAddProduct(uint256 price, string memory title) public {
        _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: eCommerceHomeblockchainId,
                destinationAddress: address(homeAddress),
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(ERC20Token), amount: 0}),
                requiredGasLimit: 350_000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(
                    ICommerceMessage({
                        message_type: CommerceMessageType.ADD_PRODUCT,
                        client: msg.sender,
                        payload: abi.encode(IProductInput({price: price, title: title}))
                    })
                )
            })
        );
        emit crossChainProductAdded(msg.sender);
    }

    function sendResultToHome(ICrossChainPaymentResult memory receipt, address client) internal {
        bytes memory message = abi.encode(receipt);
        bytes memory data = abi.encode(
            ICommerceMessage({message_type: CommerceMessageType.PAYMENT_RESULT, client: client, payload: message})
        );
        _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: eCommerceHomeblockchainId,
                destinationAddress: address(homeAddress),
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(ERC20Token), amount: 0}),
                requiredGasLimit: 150_000,
                allowedRelayerAddresses: new address[](0),
                message: data
            })
        );
    }

    function _receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes memory message)
        internal
        override
    {}

    function _sendToFallbackReceiver(address fallbackAddress, uint256 amount) internal {
        (bool fallbackSuccess,) =
            address(ERC20Token).call(abi.encodeCall(ERC20Token.transfer, (fallbackAddress, amount)));
        if (!fallbackSuccess) {
            address(ERC20Token).call(abi.encodeCall(ERC20Token.approve, (fallbackAddress, amount)));
        }
    }
}
