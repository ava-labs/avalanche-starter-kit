// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract CalculatorWithVRF is ITeleporterReceiver, VRFConsumerBaseV2 {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    // Chainlink VRF Config for Fuji
    VRFCoordinatorV2Interface public immutable vrfCoordinator;

    bytes32 public immutable keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
    uint64 public subscriptionId;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    // Results

    uint256 public num1Received;
    uint256 public num2Received;
    uint256 public randomNumber;
    uint256 public finalResult;

    // Request tracking

    mapping(uint256 => bool) public pendingRequests;

    constructor(address _vrfCoordinator, uint64 _subscriptionId) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);

        subscriptionId = _subscriptionId;
    }

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        require(msg.sender == address(messenger), "Unauthorized");
        (uint256 num1, uint256 num2) = abi.decode(message, (uint256, uint256));
        num1Received = num1;
        num2Received = num2;

        // Request random number from Chainlink VRF
        uint256 requestId =
            vrfCoordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);

        pendingRequests[requestId] = true;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(pendingRequests[requestId], "Request not found");
        randomNumber = (randomWords[0] % 100) + 1; // Random number between 1-100
        finalResult = num1Received + num2Received + randomNumber;
        delete pendingRequests[requestId];
    }

    function getResult() external view returns (uint256 sum, uint256 random, uint256 total) {
        return (num1Received + num2Received, randomNumber, finalResult);
    }
}
