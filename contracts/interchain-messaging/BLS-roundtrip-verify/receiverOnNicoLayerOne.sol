// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";
import "../../interfaces/IVerifyBLS.sol";
import "./VerifierActions.sol";

contract ReceiverOnNicoLayerOne is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    IVerifyBLS public constant verifyBLSPrecompile = IVerifyBLS(0x0300000000000000000000000000000000000004);

    struct VerificationResult {
        bool isSingle;
        bool verified;
    }

    VerificationResult public result;

    function receiveTeleporterMessage(bytes32 sourceBlockchainID, address originSenderAddress, bytes calldata message)
        external
    {
        // Only the TeleporterMessenger can deliver a message.
        require(msg.sender == address(messenger), "ReceiverOnNicoLayerOne: unauthorized TeleporterMessenger");

        // Decoding the Action type
        (VerifierAction actionType, bytes memory paramsData) = abi.decode(message, (VerifierAction, bytes));

        if (actionType == VerifierAction.singleVerify) {
            (string memory messageValue, bytes memory signature, bytes memory publicKey) =
                abi.decode(message, (string, bytes, bytes));
            bool verified = verifyBLSPrecompile.verifySignatureBLS(messageValue, signature, publicKey);
            // hardcoding value since precompile is not deployed
            result = VerificationResult(true, true);
        } else if (actionType == VerifierAction.aggregateVerify) {
            (string memory messageValue, bytes memory signature, bytes memory publicKey) =
                abi.decode(message, (string, bytes, bytes));
            // would probably make more sense to do the aggregation on the local c-chain
            bytes memory aggPublicKey = verifyBLSPrecompile.aggregatePublicKeys(publicKeys);
            bytes memory aggSignature = verifyBLSPrecompile.aggregateSingatures(signatures);
            // Verify using aggregated values.
            bool verified = verifyBLSPrecompile.verifySignatureBLS(messageValue, aggSignature, aggPublicKey);
            // hardcoding value since precompile is not deployed
            result = VerificationResult(false, true);
        } else {
            revert("ReceiverOnLayerOne: invalid action");
        }

        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // Use the source blockchain ID for the destination.
                destinationBlockchainID: sourceBlockchainID,
                destinationAddress: originSenderAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(isSingle, verified)
            })
        );
    }

    function verifyBLS(bool Single, string memory messageValue, bytes memory signature, bytes memory publicKey)
        internal
        view
        returns (bool, bool)
    {
        // Not good to dictate outcomes based on block timestamp,
        // just done to alternate the value for testing.
        if (bytes(messageValue).length > 0 && signature.length > 0 && publicKey.length > 0 && block.timestamp % 2 == 0)
        {
            return (Single, true);
        }
        return (Single, false);
    }
}
