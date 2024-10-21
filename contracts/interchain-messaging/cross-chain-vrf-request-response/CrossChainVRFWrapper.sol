// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.4;

import "@chainlink/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import "@chainlink/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@teleporter/ITeleporterReceiver.sol";
import "@teleporter/ITeleporterMessenger.sol";

contract CrossChainVRFWrapper is ITeleporterReceiver, VRFConsumerBaseV2Plus {

    ITeleporterMessenger public teleporterMessenger;

    struct SubscriptionInfo {
        uint256 subscriptionId;
        bool isAuthorized;
    }
    mapping(address => SubscriptionInfo) public authorizedSubscriptions;

    // Avalanche Fuji VRF 2.5 Coordinator:
    address s_vrfCoordinatorAddress = 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE;

    struct CrossChainRequest {
        bytes32 keyHash;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        bool nativePayment;
    }

    struct CrossChainResponse {
        uint256 requestId;
        uint256[] randomWords;
    }

    struct CrossChainReceiver {
        bytes32 destinationBlockchainId;
        address destinationAddress;
    }
    mapping(uint256 => CrossChainReceiver) public pendingRequests;

    constructor(address _teleporterMessenger) VRFConsumerBaseV2Plus(s_vrfCoordinatorAddress) {
        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
    }

    function receiveTeleporterMessage(
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external {
        require(msg.sender == address(teleporterMessenger), "Caller is not the TeleporterMessenger");
        // Verify that the origin sender address is authorized
        require(authorizedSubscriptions[originSenderAddress].isAuthorized, "Origin sender is not authorized");
        uint256 subscriptionId = authorizedSubscriptions[originSenderAddress].subscriptionId;
        // Verify that the subscription ID belongs to the correct owner
        (,,,, address[] memory consumers) = s_vrfCoordinator.getSubscription(subscriptionId);
        // Check wrapper contract is a consumer of the subscription
        bool isConsumer = false;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == address(this)) {
                isConsumer = true;
                break;
            }
        }
        require(isConsumer, "Contract is not a consumer of this subscription");
        // Decode message to get the VRF parameters
        CrossChainRequest memory vrfMessage = abi.decode(message, (CrossChainRequest));
        // Request random words
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: vrfMessage.keyHash,
            subId: subscriptionId,
            requestConfirmations: vrfMessage.requestConfirmations,
            callbackGasLimit: vrfMessage.callbackGasLimit,
            numWords: vrfMessage.numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: vrfMessage.nativePayment}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(req);
        pendingRequests[requestId] = CrossChainReceiver({
            destinationBlockchainId: originChainID,
            destinationAddress: originSenderAddress
        });
    }

    function addAuthorizedAddress(address caller, uint256 subscriptionId) external {
        // Verify that the subscription ID belongs to the correct owner
        (,,, address owner,) = s_vrfCoordinator.getSubscription(subscriptionId);
        require(owner == msg.sender, "Origin sender is not the owner of the subscription");
        // Add subscription
        authorizedSubscriptions[caller] = SubscriptionInfo({
            subscriptionId: subscriptionId,
            isAuthorized: true
        });
    }

    function removeAuthorizedAddress(address _address) external {
        require(authorizedSubscriptions[_address].isAuthorized, "Address is not authorized");
        uint256 subscriptionId = authorizedSubscriptions[_address].subscriptionId;
        // Verify that the subscription ID belongs to the correct owner
        (,,, address owner,) = s_vrfCoordinator.getSubscription(subscriptionId);
        require(owner == msg.sender, "Origin sender is not the owner of the subscription");
        delete authorizedSubscriptions[_address];
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        require(pendingRequests[requestId].destinationAddress != address(0), "Invalid request ID");
        // Create CrossChainResponse struct
        CrossChainResponse memory crossChainResponse = CrossChainResponse({
            requestId: requestId,
            randomWords: randomWords
        });
        bytes memory encodedMessage = abi.encode(crossChainResponse);
        // Send cross chain message using ITeleporterMessenger interface
        TeleporterMessageInput memory messageInput = TeleporterMessageInput({
            destinationBlockchainID: pendingRequests[requestId].destinationBlockchainId,
            destinationAddress: pendingRequests[requestId].destinationAddress,
            feeInfo: TeleporterFeeInfo({ feeTokenAddress: address(0), amount: 0 }),
            requiredGasLimit: 100000,
            allowedRelayerAddresses: new address[](0),
            message: encodedMessage
        });
        teleporterMessenger.sendCrossChainMessage(messageInput);
        delete pendingRequests[requestId];
    }
}
