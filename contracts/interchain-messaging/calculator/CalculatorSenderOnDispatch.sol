// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";

contract CalculatorSenderOnDispatch {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    // Fuji C-Chain Blockchain ID
    bytes32 constant C_CHAIN_BLOCKCHAIN_ID = 0x7fc93d85c6d62c5b2ac0b519c87010ea5294012d1e407030d6acd0021cac10d5;

    function sendNumbers(address receiverAddress, uint256 num1, uint256 num2) external {
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: C_CHAIN_BLOCKCHAIN_ID,
                destinationAddress: receiverAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(num1, num2)
            })
        );
    }
}
