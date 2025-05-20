// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/upgrades/TeleporterRegistry.sol";
import "@teleporter/ITeleporterMessenger.sol";
import "./BridgeActions.sol";

contract ERC20MinterSenderOnCChain {
    // The Teleporter registry contract manages different Teleporter contract versions.
    TeleporterRegistry public immutable teleporterRegistry =
        TeleporterRegistry(0x827364Da64e8f8466c23520d81731e94c8DDe510);

    /**
     * @dev Sends a message to another chain.
     */
    function sendCreateTokenMessage(address destinationAddress, string memory name, string memory symbol) external {
        ITeleporterMessenger messenger = teleporterRegistry.getLatestTeleporter();

        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // BlockchainID of Dispatch L1
                destinationBlockchainID: 0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: encodeCreateTokenData(name, symbol)
            })
        );
    }

    function sendMintTokenMessage(address destinationAddress, address to, uint256 amount) external {
        ITeleporterMessenger messenger = teleporterRegistry.getLatestTeleporter();

        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // BlockchainID of Dispatch L1
                destinationBlockchainID: 0x9f3be606497285d0ffbb5ac9ba24aa60346a9b1812479ed66cb329f394a4b1c7,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 100000,
                allowedRelayerAddresses: new address[](0),
                message: encodeMintTokenData(to, amount)
            })
        );
    }

    //Encode helpers
    function encodeCreateTokenData(string memory name, string memory symbol) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(name, symbol);
        return abi.encode(BridgeAction.createToken, paramsData);
    }

    function encodeMintTokenData(address to, uint256 amount) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(to, amount);
        return abi.encode(BridgeAction.mintToken, paramsData);
    }
}
