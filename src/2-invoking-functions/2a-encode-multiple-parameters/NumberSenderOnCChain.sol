// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;
import "@teleporter/ITeleporterMessenger.sol";

contract NumberSenderOnCChain {

    ITeleporterMessenger public immutable teleporterMessenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    /**
     * @dev Sends a message to another chain.
     */
  function sendNumbers(address destinationAddress, uint256 num1, uint256 num2) external {

    bytes memory message = abi.encode(
      num1,
      num2
    );

    teleporterMessenger.sendCrossChainMessage(
      TeleporterMessageInput({
         // Replace with blockchainID of your Subnet (see instructions in Readme)
        destinationBlockchainID: 0x3861e061737eaeb8d00f0514d210ad1062bfacdb4bd22d1d1f5ef876ae3a8921,
        destinationAddress: destinationAddress,
        feeInfo: TeleporterFeeInfo({
          feeTokenAddress: address(0),
          amount: 0
          }),
        requiredGasLimit: 100000,
        allowedRelayerAddresses: new address[](0),
        message: message
        })
    );
  }
}