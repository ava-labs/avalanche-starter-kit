// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {
    BridgeNFT,
    ERC721Bridge,
    ExampleERC721,
    IERC721,
    IERC721Bridge,
    TeleporterMessageInput,
    TeleporterFeeInfo,
    IWarpMessenger,
    ITeleporterMessenger
} from "./ERC721Bridge.sol";
import {TeleporterRegistry} from "@teleporter/upgrades/TeleporterRegistry.sol";
import {ExampleERC721} from "./ExampleERC721.sol";
import {Strings} from "@openzeppelin/contracts@4.8.1/utils/Strings.sol";

contract ERC721BridgeTest is Test {
    address public constant MOCK_TELEPORTER_MESSENGER_ADDRESS = 0x644E5b7c5D4Bc8073732CEa72c66e0BB90dFC00f;
    address public constant MOCK_TELEPORTER_REGISTRY_ADDRESS = 0xf9FA4a0c696b659328DDaaBCB46Ae4eBFC9e68e4;
    address public constant WARP_PRECOMPILE_ADDRESS = address(0x0200000000000000000000000000000000000005);
    bytes32 internal constant _MOCK_MESSAGE_ID =
        bytes32(hex"1111111111111111111111111111111111111111111111111111111111111111");
    bytes32 private constant _MOCK_BLOCKCHAIN_ID = bytes32(uint256(123456));
    bytes32 private constant _DEFAULT_OTHER_CHAIN_ID =
        bytes32(hex"abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd");
    address private constant _DEFAULT_OTHER_BRIDGE_ADDRESS = 0xd54e3E251b9b0EEd3ed70A858e927bbC2659587d;
    string private constant _DEFAULT_TOKEN_NAME = "Test Token";
    string private constant _DEFAULT_SYMBOL = "TSTTK";
    string private constant _DEFAULT_TOKEN_URI = "https://example.com/ipfs/";
    address private constant _DEFAULT_RECIPIENT = 0xa4CEE7d1aF6aDdDD33E3b1cC680AB84fdf1b6d1d;

    ERC721Bridge public erc721Bridge;
    ExampleERC721 public mockERC721;

    event BridgeToken(
        address indexed tokenContractAddress,
        bytes32 indexed destinationBlockchainID,
        bytes32 indexed teleporterMessageID,
        address destinationBridgeAddress,
        address recipient,
        uint256 tokenId
    );

    event SubmitCreateBridgeNFT(
        bytes32 indexed destinationBlockchainID,
        address indexed destinationBridgeAddress,
        address indexed nativeContractAddress,
        bytes32 teleporterMessageID
    );

    event CreateBridgeNFT(
        bytes32 indexed nativeBlockchainID,
        address indexed nativeBridgeAddress,
        address indexed nativeContractAddress,
        address bridgeNFTAddress
    );

    event MintBridgeNFT(address indexed contractAddress, address recipient, uint256 tokenId);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public virtual {
        vm.mockCall(
            WARP_PRECOMPILE_ADDRESS,
            abi.encodeWithSelector(IWarpMessenger.getBlockchainID.selector),
            abi.encode(_MOCK_BLOCKCHAIN_ID)
        );
        vm.expectCall(WARP_PRECOMPILE_ADDRESS, abi.encodeWithSelector(IWarpMessenger.getBlockchainID.selector));

        _initMockTeleporterRegistry();

        vm.expectCall(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            abi.encodeWithSelector(TeleporterRegistry(MOCK_TELEPORTER_REGISTRY_ADDRESS).latestVersion.selector)
        );

        erc721Bridge = new ERC721Bridge(MOCK_TELEPORTER_REGISTRY_ADDRESS);
        mockERC721 = new ExampleERC721();
    }

    function testSameBlockchainID() public {
        vm.expectRevert(IERC721Bridge.InvalidDestinationBlockchainId.selector);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _MOCK_BLOCKCHAIN_ID,
            destinationBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            tokenContractAddress: address(mockERC721),
            recipient: _DEFAULT_RECIPIENT,
            tokenId: 1,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function testZeroDestinationBridgeAddress() public {
        vm.expectRevert(IERC721Bridge.ZeroDestinationBridgeAddress.selector);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            destinationBridgeAddress: address(0),
            tokenContractAddress: address(mockERC721),
            recipient: _DEFAULT_RECIPIENT,
            tokenId: 1,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function testZeroNFTContractAddress() public {
        vm.expectRevert(IERC721Bridge.ZeroTokenContractAddress.selector);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            destinationBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            tokenContractAddress: address(0),
            recipient: _DEFAULT_RECIPIENT,
            tokenId: 1,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function testZeroRecipient() public {
        vm.expectRevert(IERC721Bridge.ZeroRecipientAddress.selector);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            destinationBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            tokenContractAddress: address(mockERC721),
            recipient: address(0),
            tokenId: 1,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function testInvalidBridgeNFTContract() public {
        vm.expectRevert(IERC721Bridge.TokenContractNotBridged.selector);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            destinationBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            tokenContractAddress: address(mockERC721),
            recipient: _DEFAULT_RECIPIENT,
            tokenId: 1,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function testAlreadyBridgedTokenId() public {
        uint256 tokenId = 1;

        // For the test purposes we will mint the NFT to the bridge contract directly  to simulate the NFT being already bridged.
        // Otherwise we would need to mint it to the user, then allow the bridge contract to transfer it, bridge it, and then
        // try to  bridge it again.
        vm.prank(address(erc721Bridge));
        mockERC721.mint(tokenId);

        // Bridge the NFT.
        _setUpMockERC721ContractValues(address(mockERC721));
        _submitCreateBridgeERC721(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, address(mockERC721));

        vm.expectRevert(IERC721Bridge.InvalidTokenId.selector);
        vm.prank(_DEFAULT_RECIPIENT);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            destinationBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            tokenContractAddress: address(mockERC721),
            recipient: _DEFAULT_RECIPIENT,
            tokenId: tokenId,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function testNotOwnerOfTokenID() public {
        uint256 tokenId = 1;
        vm.prank(address(1));
        mockERC721.mint(tokenId);

        // Bridge the NFT.
        _setUpMockERC721ContractValues(address(mockERC721));
        _submitCreateBridgeERC721(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, address(mockERC721));

        vm.expectRevert(IERC721Bridge.InvalidTokenId.selector);
        vm.prank(_DEFAULT_RECIPIENT);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            destinationBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            tokenContractAddress: address(mockERC721),
            recipient: _DEFAULT_RECIPIENT,
            tokenId: tokenId,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function testLockNativeNFT() public {
        uint256 tokenId = 1;

        // Mint the token to the default recipient.
        // Approve the bridge contract to manage the token.

        vm.startPrank(_DEFAULT_RECIPIENT);
        mockERC721.mint(tokenId);
        mockERC721.approve(address(erc721Bridge), tokenId);
        vm.stopPrank();

        // Bridge the NFT.
        _setUpMockERC721ContractValues(address(mockERC721));
        _submitCreateBridgeERC721(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, address(mockERC721));
        _setUpExpectedTransferFromCall(address(mockERC721), _DEFAULT_RECIPIENT, address(erc721Bridge), tokenId);
        _submitBridgeERC721(
            _DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, address(mockERC721), _DEFAULT_RECIPIENT, tokenId
        );

        // Check that the NFT was locked in the bridge contract.
        assertEq(address(erc721Bridge), mockERC721.ownerOf(tokenId));
    }

    function testNewBridgeNFTMint() public {
        uint256 tokenId = 1;

        address bridgeNFTAddress = _setupBridgeNFT({
            nativeBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            nativeBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            nativeContractAddress: address(mockERC721),
            nativeName: _DEFAULT_TOKEN_NAME,
            nativeSymbol: _DEFAULT_SYMBOL,
            nativeTokenURI: _DEFAULT_TOKEN_URI,
            contractNonce: 1
        });

        bytes memory message = erc721Bridge.encodeMintBridgeNFTData(
            IERC721Bridge.MintBridgeNFTData(address(mockERC721), _DEFAULT_RECIPIENT, tokenId)
        );

        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        vm.expectEmit(true, true, true, true, address(erc721Bridge));
        emit MintBridgeNFT(bridgeNFTAddress, _DEFAULT_RECIPIENT, tokenId);
        _setUpExpectedMintCall(bridgeNFTAddress, _DEFAULT_RECIPIENT, tokenId);
        erc721Bridge.receiveTeleporterMessage(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, message);

        // Check the values of the newly created ERC721.
        BridgeNFT newBridgeNFT = BridgeNFT(bridgeNFTAddress);
        assertEq(_DEFAULT_TOKEN_NAME, newBridgeNFT.name());
        assertEq(_DEFAULT_SYMBOL, newBridgeNFT.symbol());
        assertEq(_DEFAULT_OTHER_CHAIN_ID, newBridgeNFT.nativeBlockchainID());
        assertEq(_DEFAULT_OTHER_BRIDGE_ADDRESS, newBridgeNFT.nativeBridge());
        assertEq(address(mockERC721), newBridgeNFT.nativeAsset());

        // Check that the NFT was minted to the recipient on the bridge chain.
        assertEq(_DEFAULT_RECIPIENT, newBridgeNFT.ownerOf(tokenId));
    }

    function testNewBridgeNFTBurnNotApproved() public {
        uint256 tokenId = 1;

        // Setup BridgeNFT contract and mint the token to the default recipient on the bridged chain.
        address bridgeNFTAddress = _setupBridgeNFT({
            nativeBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            nativeBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            nativeContractAddress: address(mockERC721),
            nativeName: _DEFAULT_TOKEN_NAME,
            nativeSymbol: _DEFAULT_SYMBOL,
            nativeTokenURI: _DEFAULT_TOKEN_URI,
            contractNonce: 1
        });

        bytes memory message = erc721Bridge.encodeMintBridgeNFTData(
            IERC721Bridge.MintBridgeNFTData(address(mockERC721), _DEFAULT_RECIPIENT, tokenId)
        );

        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        vm.expectEmit(true, true, true, true, address(erc721Bridge));
        emit MintBridgeNFT(bridgeNFTAddress, _DEFAULT_RECIPIENT, tokenId);
        _setUpExpectedMintCall(bridgeNFTAddress, _DEFAULT_RECIPIENT, tokenId);
        erc721Bridge.receiveTeleporterMessage(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, message);

        assertEq(_DEFAULT_RECIPIENT, BridgeNFT(bridgeNFTAddress).ownerOf(tokenId));

        vm.expectRevert("BridgeNFT: caller is not token owner or approved");
        // Call bridgeToken on the ERC721Bridge contract to burn and transfer the token without approving the bridge contract to manage the token.
        vm.prank(_DEFAULT_RECIPIENT);
        erc721Bridge.bridgeToken(
            _DEFAULT_OTHER_CHAIN_ID,
            _DEFAULT_OTHER_BRIDGE_ADDRESS,
            bridgeNFTAddress,
            _DEFAULT_RECIPIENT,
            tokenId,
            address(0),
            0
        );
    }

    function testNewBridgeNFTBurnInvalidTokenID() public {
        // Setup BridgeNFT contract and mint the token to the default recipient on the bridged chain.
        address bridgeNFTAddress = _setupBridgeNFT({
            nativeBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            nativeBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            nativeContractAddress: address(mockERC721),
            nativeName: _DEFAULT_TOKEN_NAME,
            nativeSymbol: _DEFAULT_SYMBOL,
            nativeTokenURI: _DEFAULT_TOKEN_URI,
            contractNonce: 1
        });

        vm.expectRevert(IERC721Bridge.InvalidTokenId.selector);
        // Call bridgeToken on the ERC721Bridge contract to burn and transfer a token that does not exist on the bridged chain.
        vm.prank(_DEFAULT_RECIPIENT);
        erc721Bridge.bridgeToken(
            _DEFAULT_OTHER_CHAIN_ID,
            _DEFAULT_OTHER_BRIDGE_ADDRESS,
            bridgeNFTAddress,
            _DEFAULT_RECIPIENT,
            1234,
            address(0),
            0
        );
    }

    function testNewBridgeNFTBurnOnTransfer() public {
        uint256 tokenId = 1;

        // Setup BridgeNFT contract and mint the token to the default recipient on the bridged chain.
        address bridgeNFTAddress = _setupBridgeNFT({
            nativeBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            nativeBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            nativeContractAddress: address(mockERC721),
            nativeName: _DEFAULT_TOKEN_NAME,
            nativeSymbol: _DEFAULT_SYMBOL,
            nativeTokenURI: _DEFAULT_TOKEN_URI,
            contractNonce: 1
        });

        bytes memory message = erc721Bridge.encodeMintBridgeNFTData(
            IERC721Bridge.MintBridgeNFTData(address(mockERC721), _DEFAULT_RECIPIENT, tokenId)
        );

        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        vm.expectEmit(true, true, true, true, address(erc721Bridge));
        emit MintBridgeNFT(bridgeNFTAddress, _DEFAULT_RECIPIENT, tokenId);
        _setUpExpectedMintCall(bridgeNFTAddress, _DEFAULT_RECIPIENT, tokenId);
        erc721Bridge.receiveTeleporterMessage(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, message);

        assertEq(_DEFAULT_RECIPIENT, BridgeNFT(bridgeNFTAddress).ownerOf(tokenId));

        // Approve OTHER BRIDGE ADDRESS to manage the bridged token.
        vm.prank(_DEFAULT_RECIPIENT);
        BridgeNFT(bridgeNFTAddress).approve(address(erc721Bridge), tokenId);

        // Call bridgeToken on the ERC721Bridge contract to burn and transfer the token on the bridged chain.
        vm.expectCall(bridgeNFTAddress, abi.encodeWithSignature("burn(uint256)", tokenId));
        _setupMockTransferBridgeNFTCall(
            _DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, address(mockERC721), _DEFAULT_RECIPIENT, tokenId
        );
        // Expect a Transfer event to be emitted from the BridgeNFT contract.
        vm.expectEmit(true, true, true, true, bridgeNFTAddress);
        emit Transfer(_DEFAULT_RECIPIENT, address(0), tokenId);
        vm.expectEmit(true, true, true, true, address(erc721Bridge));
        emit BridgeToken(
            bridgeNFTAddress,
            _DEFAULT_OTHER_CHAIN_ID,
            _MOCK_MESSAGE_ID,
            _DEFAULT_OTHER_BRIDGE_ADDRESS,
            _DEFAULT_RECIPIENT,
            tokenId
        );

        vm.prank(_DEFAULT_RECIPIENT);
        erc721Bridge.bridgeToken(
            _DEFAULT_OTHER_CHAIN_ID,
            _DEFAULT_OTHER_BRIDGE_ADDRESS,
            bridgeNFTAddress,
            _DEFAULT_RECIPIENT,
            tokenId,
            address(0),
            0
        );

        // Check the NFT was transferred to the zero address on the bridged chain.
        // ownerOf will revert if the token does not exist.
        vm.expectRevert("ERC721: invalid token ID");
        BridgeNFT(bridgeNFTAddress).ownerOf(tokenId);
    }

    function testUnlockTokenOnTransfer() public {
        uint256 tokenId = 1;

        // Mint the token to the default recipient.
        // Approve the bridge contract to manage the token.
        vm.startPrank(_DEFAULT_RECIPIENT);
        mockERC721.mint(tokenId);
        mockERC721.approve(address(erc721Bridge), tokenId);
        vm.stopPrank();

        // Bridge the NFT.
        _setUpMockERC721ContractValues(address(mockERC721));
        _submitCreateBridgeERC721(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, address(mockERC721));
        _setUpExpectedTransferFromCall(address(mockERC721), _DEFAULT_RECIPIENT, address(erc721Bridge), tokenId);
        _submitBridgeERC721(
            _DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, address(mockERC721), _DEFAULT_RECIPIENT, tokenId
        );

        // Check that the NFT was transferred to the recipient on the bridge chain.
        assertEq(address(erc721Bridge), mockERC721.ownerOf(tokenId));

        // Recieve Transfer teleporter message and unlock the NFT
        bytes memory transferMessage = erc721Bridge.encodeTransferBridgeNFTData(
            IERC721Bridge.TransferBridgeNFTData(
                _MOCK_BLOCKCHAIN_ID, address(erc721Bridge), address(mockERC721), _DEFAULT_RECIPIENT, tokenId
            )
        );

        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        _setUpExpectedTransferFromCall(address(mockERC721), address(erc721Bridge), _DEFAULT_RECIPIENT, tokenId);
        erc721Bridge.receiveTeleporterMessage(_DEFAULT_OTHER_CHAIN_ID, _DEFAULT_OTHER_BRIDGE_ADDRESS, transferMessage);

        // Check that the NFT was transferred to the recipient on the bridge chain.
        assertEq(_DEFAULT_RECIPIENT, mockERC721.ownerOf(tokenId));
    }

    function testZeroTeleporterRegistryAddress() public {
        vm.expectRevert("TeleporterUpgradeable: zero teleporter registry address");
        new ERC721Bridge(address(0));
    }

    function _initMockTeleporterRegistry() internal {
        vm.mockCall(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            abi.encodeWithSelector(TeleporterRegistry(MOCK_TELEPORTER_REGISTRY_ADDRESS).latestVersion.selector),
            abi.encode(1)
        );

        vm.mockCall(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            abi.encodeWithSelector(
                TeleporterRegistry.getVersionFromAddress.selector, (MOCK_TELEPORTER_MESSENGER_ADDRESS)
            ),
            abi.encode(1)
        );

        vm.mockCall(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            abi.encodeWithSelector(TeleporterRegistry.getAddressFromVersion.selector, (1)),
            abi.encode(MOCK_TELEPORTER_MESSENGER_ADDRESS)
        );

        vm.mockCall(
            MOCK_TELEPORTER_REGISTRY_ADDRESS,
            abi.encodeWithSelector(TeleporterRegistry.getLatestTeleporter.selector),
            abi.encode(ITeleporterMessenger(MOCK_TELEPORTER_MESSENGER_ADDRESS))
        );
    }

    function _setUpExpectedMintCall(address nftContract, address recipient, uint256 tokenId) private {
        vm.expectCall(nftContract, abi.encodeCall(BridgeNFT.mint, (recipient, tokenId)));
    }

    function _setUpExpectedTransferFromCall(address nftContract, address from, address to, uint256 tokenId) private {
        vm.expectCall(
            nftContract, abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from, to, tokenId)
        );
    }

    // Calls submitCreateBridgeERC721 of the test's ERC721Bridge instance to add the specified
    // token to be able to be sent to the specified remote bridge. Checks that the expected
    // call to the Teleporter contract is made and that the expected event is emitted. This is
    // required before attempting to call bridgeTokens for the given token and bridge.
    function _submitCreateBridgeERC721(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        address nativeContractAddress
    ) private {
        ExampleERC721 nativeToken = ExampleERC721(nativeContractAddress);

        TeleporterMessageInput memory expectedMessageInput = TeleporterMessageInput({
            destinationBlockchainID: destinationBlockchainID,
            destinationAddress: destinationBridgeAddress,
            feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
            requiredGasLimit: erc721Bridge.CREATE_BRIDGE_TOKENS_REQUIRED_GAS(),
            allowedRelayerAddresses: new address[](0),
            message: erc721Bridge.encodeCreateBridgeNFTData(
                IERC721Bridge.CreateBridgeNFTData(
                    nativeContractAddress, nativeToken.name(), nativeToken.symbol(), nativeToken.baseUri()
                )
                )
        });

        vm.mockCall(
            MOCK_TELEPORTER_MESSENGER_ADDRESS,
            abi.encodeCall(ITeleporterMessenger.sendCrossChainMessage, (expectedMessageInput)),
            abi.encode(_MOCK_MESSAGE_ID)
        );
        vm.expectCall(
            MOCK_TELEPORTER_MESSENGER_ADDRESS,
            abi.encodeCall(ITeleporterMessenger.sendCrossChainMessage, (expectedMessageInput))
        );

        vm.expectEmit(true, true, true, true, address(erc721Bridge));
        emit SubmitCreateBridgeNFT(
            destinationBlockchainID, destinationBridgeAddress, address(nativeToken), _MOCK_MESSAGE_ID
        );

        erc721Bridge.submitCreateBridgeNFT({
            destinationBlockchainID: destinationBlockchainID,
            destinationBridgeAddress: destinationBridgeAddress,
            nativeContract: nativeToken,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    // Calls bridgeERC721 of the test's ERC721Bridge instance to bridge the specified token to the
    // specified remote bridge. Checks that the expected call to the Teleporter contract is
    // made and that the expected event is emitted.
    function _submitBridgeERC721(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        address nativeContractAddress,
        address recipient,
        uint256 tokenId
    ) private {
        _setupMockMintBridgeNFTCall(
            destinationBlockchainID, destinationBridgeAddress, nativeContractAddress, recipient, tokenId
        );

        vm.expectEmit(true, true, true, true, address(erc721Bridge));
        emit BridgeToken(
            nativeContractAddress,
            destinationBlockchainID,
            _MOCK_MESSAGE_ID,
            destinationBridgeAddress,
            recipient,
            tokenId
        );

        vm.prank(_DEFAULT_RECIPIENT);
        erc721Bridge.bridgeToken({
            destinationBlockchainID: _DEFAULT_OTHER_CHAIN_ID,
            destinationBridgeAddress: _DEFAULT_OTHER_BRIDGE_ADDRESS,
            tokenContractAddress: nativeContractAddress,
            recipient: _DEFAULT_RECIPIENT,
            tokenId: tokenId,
            messageFeeAsset: address(0),
            messageFeeAmount: 0
        });
    }

    function _setupMockMintBridgeNFTCall(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        address nativeContractAddress,
        address recipient,
        uint256 tokenId
    ) private {
        TeleporterMessageInput memory expectedMessageInput = TeleporterMessageInput({
            destinationBlockchainID: destinationBlockchainID,
            destinationAddress: destinationBridgeAddress,
            feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
            requiredGasLimit: erc721Bridge.MINT_BRIDGE_TOKENS_REQUIRED_GAS(),
            allowedRelayerAddresses: new address[](0),
            message: erc721Bridge.encodeMintBridgeNFTData(
                IERC721Bridge.MintBridgeNFTData(nativeContractAddress, recipient, tokenId)
                )
        });

        vm.mockCall(
            MOCK_TELEPORTER_MESSENGER_ADDRESS,
            abi.encodeCall(ITeleporterMessenger.sendCrossChainMessage, (expectedMessageInput)),
            abi.encode(_MOCK_MESSAGE_ID)
        );
        vm.expectCall(
            MOCK_TELEPORTER_MESSENGER_ADDRESS,
            abi.encodeCall(ITeleporterMessenger.sendCrossChainMessage, (expectedMessageInput))
        );
    }

    function _setupMockTransferBridgeNFTCall(
        bytes32 destinationBlockchainID,
        address destinationBridgeAddress,
        address nativeContractAddress,
        address recipient,
        uint256 tokenId
    ) private {
        TeleporterMessageInput memory expectedMessageInput = TeleporterMessageInput({
            destinationBlockchainID: destinationBlockchainID,
            destinationAddress: destinationBridgeAddress,
            feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
            requiredGasLimit: erc721Bridge.TRANSFER_BRIDGE_TOKENS_REQUIRED_GAS(),
            allowedRelayerAddresses: new address[](0),
            message: erc721Bridge.encodeTransferBridgeNFTData(
                IERC721Bridge.TransferBridgeNFTData(
                    destinationBlockchainID, destinationBridgeAddress, nativeContractAddress, recipient, tokenId
                )
                )
        });

        vm.mockCall(
            MOCK_TELEPORTER_MESSENGER_ADDRESS,
            abi.encodeCall(ITeleporterMessenger.sendCrossChainMessage, (expectedMessageInput)),
            abi.encode(_MOCK_MESSAGE_ID)
        );
        vm.expectCall(
            MOCK_TELEPORTER_MESSENGER_ADDRESS,
            abi.encodeCall(ITeleporterMessenger.sendCrossChainMessage, (expectedMessageInput))
        );
    }

    function _setupBridgeNFT(
        bytes32 nativeBlockchainID,
        address nativeBridgeAddress,
        address nativeContractAddress,
        string memory nativeName,
        string memory nativeSymbol,
        string memory nativeTokenURI,
        uint8 contractNonce
    ) private returns (address) {
        address expectedBridgeNFTAddress = _deriveExpectedContractAddress(address(erc721Bridge), contractNonce);
        bytes memory message = erc721Bridge.encodeCreateBridgeNFTData(
            IERC721Bridge.CreateBridgeNFTData(nativeContractAddress, nativeName, nativeSymbol, nativeTokenURI)
        );
        vm.prank(MOCK_TELEPORTER_MESSENGER_ADDRESS);
        vm.expectEmit(true, true, true, true, address(erc721Bridge));
        emit CreateBridgeNFT(nativeBlockchainID, nativeBridgeAddress, nativeContractAddress, expectedBridgeNFTAddress);
        erc721Bridge.receiveTeleporterMessage(nativeBlockchainID, nativeBridgeAddress, message);

        return expectedBridgeNFTAddress;
    }

    function _setUpMockERC721ContractValues(address nftContract) private {
        ExampleERC721 token = ExampleERC721(nftContract);
        vm.mockCall(nftContract, abi.encodeCall(token.name, ()), abi.encode(_DEFAULT_TOKEN_NAME));
        vm.expectCall(nftContract, abi.encodeCall(token.name, ()));
        vm.mockCall(nftContract, abi.encodeCall(token.symbol, ()), abi.encode(_DEFAULT_SYMBOL));
        vm.expectCall(nftContract, abi.encodeCall(token.symbol, ()));
    }

    function _deriveExpectedContractAddress(address creator, uint8 nonce) private pure returns (address) {
        // Taken from https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed
        // We must use encodePacked rather than encode so that the parameters are not padded with extra zeros.
        return
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), creator, bytes1(nonce))))));
    }

    function _formatERC721BridgeErrorMessage(string memory errorMessage) private pure returns (bytes memory) {
        return bytes(string.concat("ERC721Bridge: ", errorMessage));
    }
}
