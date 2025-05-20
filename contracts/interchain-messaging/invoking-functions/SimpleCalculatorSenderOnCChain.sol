// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";

contract SimpleCalculatorSenderOnCChain {
    ITeleporterMessenger public immutable teleporterMessenger =
        ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    function sendAddMessage(address destinationAddress, uint256 num1, uint256 num2) external {
        teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // BlockchainID of Dispatch L1
                destinationBlockchainID: 0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7, 
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: encodeAddData(num1, num2)
            })
        );
    }

    //Encode helpers
    function encodeAddData(uint256 a, uint256 b) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(a, b);
        return paramsData;
    }
}
