// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import "https://github.com/ava-labs/teleporter/blob/main/contracts/src/Teleporter/ITeleporterMessenger.sol";
import {IERC20} from "@openzeppelin/contracts@4/token/ERC20/IERC20.sol";

contract NFTMinterSenderWithFeesOnSource {
    ITeleporterMessenger public immutable teleporterMessenger =
        ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);
    IERC20 feeContract = IERC20(<your_fee_token_address>);

    enum Action {
        createNFT,
        mintNFT
    }

    function sendCreateNFTMessage(address destinationAddress, string memory name, string memory symbol)
        external
        returns (bytes32 messageID)
    {
        uint256 feeAmount = 500000000000000;
        feeContract.transferFrom(msg.sender, address(this), feeAmount);

        feeContract.approve(address(teleporterMessenger), feeAmount);
        return teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: <your_blockchain_id>,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: <your_fee_token_address>, amount: feeAmount}),
                requiredGasLimit: 10000000,
                allowedRelayerAddresses: new address[](0),
                message: encodeCreateNFTData(name, symbol)
            })
        );
    }

    function sendMintNFTMessage(address destinationAddress, address to, uint256 tokenId)
        external
        returns (bytes32 messageID)
    {
        return teleporterMessenger.sendCrossChainMessage(
            TeleporterMessageInput({
                destinationBlockchainID: <your_blockchain_id>,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 10000000,
                allowedRelayerAddresses: new address[](0),
                message: encodeMintNFTData(to, tokenId)
            })
        );
    }

    //Encode helpers
    function encodeCreateNFTData(string memory name, string memory symbol) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(name, symbol);
        return abi.encode(Action.createNFT, paramsData);
    }

    function encodeMintNFTData(address to, uint256 tokenId) public pure returns (bytes memory) {
        bytes memory paramsData = abi.encode(to, tokenId);
        return abi.encode(Action.mintNFT, paramsData);
    }
}
