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
import {INativeCommerceRemote} from "./interfaces/INativeCommerceRemote.sol";
import {INativeTokenBridge} from "@avalanche-interchain-token-transfer/interfaces/INativeTokenBridge.sol";
import {TeleporterMessageInput, TeleporterFeeInfo} from "@teleporter/ITeleporterMessenger.sol";
import {SendAndCallInput, SendTokensInput} from "@avalanche-interchain-token-transfer/interfaces/ITokenBridge.sol";
import {INativeSendAndCallReceiver} from
    "@avalanche-interchain-token-transfer/interfaces/INativeSendAndCallReceiver.sol";

contract NativeMultichainEcommerceRemote is
    INativeCommerceRemote,
    TeleporterOwnerUpgradeable,
    INativeSendAndCallReceiver
{
    INativeTokenBridge public RemoteTokenTransferrer;
    address public eCommerceHomeTokenTransferrer;
    bytes32 public blockchainId;
    bytes32 public eCommerceHomeblockchainId;
    address CommerceHome;
    bytes32 homeTokenTransferrerBlockchainID;

    constructor(
        address teleporterRegistryAddress,
        address initialOwner,
        address RemoteTokenTransferrer_,
        address eCommerceHomeTokenTransferrer_,
        bytes32 blockchainId_,
        bytes32 eCommerceHomeblockchainId_,
        address commerceHome_,
        bytes32 homeTokenTransferrerBlockchainID_
    ) TeleporterOwnerUpgradeable(teleporterRegistryAddress, initialOwner) {
        RemoteTokenTransferrer = INativeTokenBridge(RemoteTokenTransferrer_);
        eCommerceHomeTokenTransferrer = eCommerceHomeTokenTransferrer_;
        blockchainId = blockchainId_;
        eCommerceHomeblockchainId = eCommerceHomeblockchainId_;
        CommerceHome = commerceHome_;
        homeTokenTransferrerBlockchainID = homeTokenTransferrerBlockchainID_;
    }

    function receiveTokens(
        bytes32 sourceBlockchainID,
        address originTokenTransferrerAddress,
        address originSenderAddress,
        bytes calldata payload
    ) external payable {
        require(sourceBlockchainID == eCommerceHomeblockchainId, "only home");
        require(originTokenTransferrerAddress == eCommerceHomeTokenTransferrer, "only home");
        require(originSenderAddress == address(CommerceHome), "only home");
        ICrossChainPayment memory payment = abi.decode(payload, (ICrossChainPayment));
        if (payment.receiverAddress == address(0)) {
            ICrossChainPaymentResult memory paymentReceipt =
                ICrossChainPaymentResult({productId: payment.productId, success: false, buyer: payment.buyer});
            emit crossChainPaymentFailed(payment.receiverAddress, payment.buyer, payment.productId);
            _sendToFallbackReceiver(payment.buyer, msg.value, originTokenTransferrerAddress, sourceBlockchainID);
            sendResultToHome(paymentReceipt, payment.buyer);
        }
        (bool success,) = payment.receiverAddress.call{value: msg.value}("");
        if (success) {
            emit crossChainPaymentReceived(payment.receiverAddress, payment.buyer, payment.productId);

            ICrossChainPaymentResult memory paymentReceipt =
                ICrossChainPaymentResult({productId: payment.productId, success: true, buyer: payment.buyer});
            sendResultToHome(paymentReceipt, payment.buyer);
        } else {
            emit crossChainPaymentFailed(payment.receiverAddress, payment.buyer, payment.productId);

            ICrossChainPaymentResult memory paymentsReceipt =
                ICrossChainPaymentResult({productId: payment.productId, success: false, buyer: payment.buyer});

            _sendToFallbackReceiver(payment.buyer, msg.value, originTokenTransferrerAddress, sourceBlockchainID);
            sendResultToHome(paymentsReceipt, payment.buyer);
        }
    }

    function crossChainBuyProduct(uint256 productId) public payable {
        bool isSingleHop = (
            (blockchainId == homeTokenTransferrerBlockchainID)
                || (eCommerceHomeblockchainId == homeTokenTransferrerBlockchainID)
        );
        RemoteTokenTransferrer.sendAndCall{value: msg.value}(
            SendAndCallInput({
                destinationBlockchainID: eCommerceHomeblockchainId,
                destinationBridgeAddress: eCommerceHomeTokenTransferrer,
                recipientContract: address(CommerceHome),
                recipientPayload: abi.encode(ITokenSentMessage({buyer: msg.sender, productId: productId})),
                requiredGasLimit: 900_000,
                recipientGasLimit: 700_000,
                multiHopFallback: isSingleHop ? address(0) : msg.sender,
                fallbackRecipient: msg.sender,
                primaryFeeTokenAddress: eCommerceHomeTokenTransferrer,
                primaryFee: 0,
                secondaryFee: 0
            })
        );
    }

    function crossChainAddProduct(uint256 price, string memory title) public {
        _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: eCommerceHomeblockchainId,
                destinationAddress: address(CommerceHome),
                feeInfo: TeleporterFeeInfo({feeTokenAddress: eCommerceHomeTokenTransferrer, amount: 0}),
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
                destinationAddress: address(CommerceHome),
                feeInfo: TeleporterFeeInfo({feeTokenAddress: eCommerceHomeTokenTransferrer, amount: 0}),
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

    function _sendToFallbackReceiver(
        address fallbackAddress,
        uint256 amount,
        address originTransferrer,
        bytes32 destinationBlockchainId
    ) internal {
        (bool fallbackSuccess,) = address(fallbackAddress).call{value: amount}("");
        if (!fallbackSuccess) {
            RemoteTokenTransferrer.send{value: msg.value}(
                SendTokensInput({
                    destinationBlockchainID: destinationBlockchainId,
                    destinationBridgeAddress: originTransferrer,
                    recipient: fallbackAddress,
                    primaryFeeTokenAddress: eCommerceHomeTokenTransferrer,
                    primaryFee: 0,
                    secondaryFee: 0,
                    requiredGasLimit: 150_000,
                    multiHopFallback: address(0)
                })
            );
        }
    }
}
