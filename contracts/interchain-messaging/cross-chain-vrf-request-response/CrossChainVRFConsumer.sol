// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.4;

import "@chainlink/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import "@teleporter/ITeleporterReceiver.sol";
import "@teleporter/ITeleporterMessenger.sol";

contract CrossChainVRFConsumer is ITeleporterReceiver {

    ITeleporterMessenger public teleporterMessenger;
    address public vrfRequesterContract;

    bytes32 constant DATASOURCE_BLOCKCHAIN_ID = 0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5;

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

    event RandomWordsReceived(uint256 requestId);

    constructor(address _teleporterMessenger, address _vrfRequesterContract) {
        teleporterMessenger = ITeleporterMessenger(_teleporterMessenger);
        vrfRequesterContract = _vrfRequesterContract;
    }

    function requestRandomWords(
        bytes32 keyHash,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        bool nativePayment,
        uint32 requiredGasLimit
    ) external {
        // Create CrossChainRequest struct
        CrossChainRequest memory crossChainRequest = CrossChainRequest({
            keyHash: keyHash,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            nativePayment: nativePayment
        });
        // Send Teleporter message
        bytes memory encodedMessage = abi.encode(crossChainRequest);
        TeleporterMessageInput memory messageInput = TeleporterMessageInput({
            destinationBlockchainID: DATASOURCE_BLOCKCHAIN_ID, 
            destinationAddress: vrfRequesterContract,
            feeInfo: TeleporterFeeInfo({ feeTokenAddress: address(0), amount: 0 }),
            requiredGasLimit: requiredGasLimit,
            allowedRelayerAddresses: new address[](0),
            message: encodedMessage
        });
        teleporterMessenger.sendCrossChainMessage(messageInput);
    }

    function receiveTeleporterMessage(
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external {
        require(originChainID == DATASOURCE_BLOCKCHAIN_ID, "Invalid originChainID");
        require(msg.sender == address(teleporterMessenger), "Caller is not the TeleporterMessenger");
        require(originSenderAddress == vrfRequesterContract, "Invalid sender");
        
        // Decode the message to get the request ID and random words
        CrossChainResponse memory response = abi.decode(message, (CrossChainResponse));
        
        // Fulfill the request by calling the internal function
        fulfillRandomWords(response.requestId, response.randomWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal {
        // Logic to handle the fulfillment of random words
        // Implement your custom logic here

        // Emit event for received random words
        emit RandomWordsReceived(requestId);
    }

}

