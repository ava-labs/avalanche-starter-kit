// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "./CalculatorActions.sol";

contract CalculatorSenderOnCChain {
    ITeleporterMessenger public immutable teleporterMessenger =
        ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    function sendAddMessage(address destinationAddress, uint256 num1, uint256 num2) external {
        teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Replace with chain id of your Subnet (see instructions in Readme)
                destinationBlockchainID: 0xd7ed7b978d4d6c478123bf9b326d47e69f959206d34e42ea4de2d1d2acbc93ea,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: encodeAddData(num1, num2)
            })
        );
    }

    function sendConcatenateMessage(address destinationAddress, string memory text1, string memory text2) external {
        teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: 0x382d2a20c299b03b638dd4d42b96e7401f6c3e88209b764abce83cf71c0c30cd,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: encodeConcatenateData(text1, text2)
            })
        );
    }

    //Encode helpers
    function encodeAddData(uint256 a, uint256 b) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(a, b);
        return abi.encode(CalculatorAction.add, paramsData);
    }

    function encodeConcatenateData(string memory a, string memory b) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(a, b);
        return abi.encode(CalculatorAction.concatenate, paramsData);
    }
}
