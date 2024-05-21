// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity 0.8.18;

import {
    TeleporterTokenDestination,
    TeleporterFeeInfo,
    TeleporterMessageInput
} from "./TeleporterTokenDestination.sol";
import {INativeMinter} from
    "@avalabs/subnet-evm-contracts@1.2.0/contracts/interfaces/INativeMinter.sol";
import {INativeTokenDestination} from "./interfaces/INativeTokenDestination.sol";
import {TeleporterTokenDestinationSettings} from "./interfaces/ITeleporterTokenDestination.sol";
import {INativeSendAndCallReceiver} from "./interfaces/INativeSendAndCallReceiver.sol";
import {TeleporterOwnerUpgradeable} from "@teleporter/upgrades/TeleporterOwnerUpgradeable.sol";
// We need IAllowList as an indirect dependency in order to compile.
// solhint-disable-next-line no-unused-import
import {IAllowList} from "@avalabs/subnet-evm-contracts@1.2.0/contracts/interfaces/IAllowList.sol";
import {IWrappedNativeToken} from "./interfaces/IWrappedNativeToken.sol";
import {
    SendTokensInput,
    SendAndCallInput,
    BridgeMessageType,
    BridgeMessage,
    SingleHopSendMessage,
    SingleHopCallMessage
} from "./interfaces/ITeleporterTokenBridge.sol";
import {ERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/ERC20.sol";
import {SendReentrancyGuard} from "./utils/SendReentrancyGuard.sol";
import {CallUtils} from "./utils/CallUtils.sol";
import {TokenScalingUtils} from "./utils/TokenScalingUtils.sol";
import {Address} from "@openzeppelin/contracts@4.8.1/utils/Address.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * @notice Implementation of the {INativeTokenDestination} interface.
 *
 * @dev This contract pairs with exactly one {TokenSource} contract on the source chain and one wrapped native
 * token on the chain this contract is deployed to.
 * It mints and burns native tokens on the destination chain corresponding to locks and unlocks on the source chain.
 */
contract NativeTokenDestination is
    ERC20,
    TeleporterOwnerUpgradeable,
    INativeTokenDestination,
    SendReentrancyGuard,
    TeleporterTokenDestination,
    IWrappedNativeToken
{
    using Address for address payable;

    /**
     * @notice The address where the burned transaction fees are credited.
     *
     * @dev Defined as BLACKHOLE_ADDRESS at
     * https://github.com/ava-labs/subnet-evm/blob/v0.6.0/constants/constants.go
     * C-Chain value found at https://github.com/ava-labs/coreth/blob/v0.13.2/constants/constants.go
     * It is a system-reserved address by default in subnet-evm and coreth, and transfers cannot be sent here manually.
     */
    address public constant BURNED_TX_FEES_ADDRESS = 0x0100000000000000000000000000000000000000;

    /**
     * @notice The address where native tokens are sent in order to be burned to bridge to other chains.
     *
     * @dev This address is distinct from {BURNED_TX_FEES_ADDRESS} so that the amount of burned transaction
     * fees and burned bridged amounts can be tracked separately.
     * This address was chosen arbitrarily.
     */
    address public constant BURNED_FOR_BRIDGE_ADDRESS = 0x0100000000000000000000000000000000010203;

    /**
     * @notice Address used to blackhole funds on the source chain, effectively burning them.
     *
     * @dev When reporting burned transaction fee amounts, this address is used as the recipient
     * address for the funds to be sent to be burned on the source chain.
     * This address was chosen arbitrarily.
     */
    address public constant SOURCE_CHAIN_BURN_ADDRESS = 0x0100000000000000000000000000000000010203;

    /**
     * @notice The native minter precompile.
     */
    INativeMinter public constant NATIVE_MINTER =
        INativeMinter(0x0200000000000000000000000000000000000001);

    /**
     * @notice Percentage of burned transaction fees that will be rewarded to a relayer delivering
     * the message created by calling calling reportBurnedTxFees().
     */
    uint256 public immutable burnedFeesReportingRewardPercentage;

    /**
     * @notice Total number of tokens minted by this contract through the native minter precompile.
     */
    uint256 public totalMinted;

    /**
     * @notice The balance of BURNED_TX_FEES_ADDRESS the last time burned fees were reported to the source chain.
     */
    uint256 public lastestBurnedFeesReported;

    /**
     * @dev When modifier is used, the function can only be called after the contract is fully collelateralized,
     * accounting for the initialReserveImbalance.
     */
    modifier onlyWhenCollateralized() {
        require(isCollateralized, "NativeTokenDestination: contract undercollateralized");
        _;
    }

    /**
     * @notice Initializes this destination token bridge instance to receive
     * tokens from the specified source chain and token bridge instance, and represents the
     * received tokens with native tokens on this chain.
     * @param settings Constructor settings for this destination token bridge instance.
     * @param nativeAssetSymbol The symbol of the native asset.
     * @param initialReserveImbalance The initial reserve imbalance that must be collateralized before minting.
     * @param decimalsShift The number of decimal places to shift the token amount by.
     * @param multiplyOnDestination See {TeleporterTokenDestination-multiplyOnDestination}.
     * @param burnedFeesReportingRewardPercentage_ The percentage of burned transaction fees
     * that will be rewarded to sender of the report.
     */
    constructor(
        TeleporterTokenDestinationSettings memory settings,
        string memory nativeAssetSymbol,
        uint256 initialReserveImbalance,
        uint8 decimalsShift,
        bool multiplyOnDestination,
        uint256 burnedFeesReportingRewardPercentage_
    )
        ERC20(string.concat("Wrapped ", nativeAssetSymbol), nativeAssetSymbol)
        TeleporterTokenDestination(
            settings,
            initialReserveImbalance,
            decimalsShift,
            multiplyOnDestination
        )
    {
        require(
            initialReserveImbalance != 0, "NativeTokenDestination: zero initial reserve imbalance"
        );

        require(
            burnedFeesReportingRewardPercentage_ < 100, "NativeTokenDestination: invalid percentage"
        );
        burnedFeesReportingRewardPercentage = burnedFeesReportingRewardPercentage_;
    }

    /**
     * @dev Receives native token with no calldata provided. The tokens are credited to the sender's
     * wrapped native token balance.
     */
    receive() external payable {
        deposit();
    }

    /**
     * @dev Fallback function for receiving native tokens. The tokens are credited to the sender's
     * wrapped native token balance.
     */
    fallback() external payable {
        deposit();
    }

    /**
     * @dev See {INativeTokenBridge-send}.
     */
    function send(SendTokensInput calldata input) external payable onlyWhenCollateralized {
        _send(input, msg.value);
    }

    /**
     * @dev See {INativeTokenBridge-sendAndCall}
     */
    function sendAndCall(SendAndCallInput calldata input) external payable onlyWhenCollateralized {
        _sendAndCall(input, msg.value);
    }

    /**
     * @dev See {INativeTokenDestination-reportTotalBurnedTxFees}.
     */
    function reportBurnedTxFees(uint256 requiredGasLimit) external sendNonReentrant {
        uint256 burnAddressBalance = BURNED_TX_FEES_ADDRESS.balance;
        require(
            burnAddressBalance > lastestBurnedFeesReported,
            "NativeTokenDestination: burn address balance not greater than last report"
        );

        uint256 burnedDifference = burnAddressBalance - lastestBurnedFeesReported;
        uint256 reward = (burnedDifference * burnedFeesReportingRewardPercentage) / 100;
        uint256 burnedTxFees = burnedDifference - reward;
        lastestBurnedFeesReported = burnAddressBalance;

        if (reward > 0) {
            // Re-mint the native tokens to this contract, and then deposit them to be the wrapped
            // native token (ERC20) representation, such that they can be used as a Teleporter
            // message fee.
            _mintNativeCoin(address(this), reward);
            _deposit(reward);
        }

        // Check that the scaled amount on the source chain will be non-zero.
        require(
            TokenScalingUtils.removeTokenScale(tokenMultiplier, multiplyOnDestination, burnedTxFees)
                > 0,
            "NativeTokenDestination: zero scaled amount to report burn"
        );

        // Returned the burned transaction fees denominated by destination bridge's token scale.
        BridgeMessage memory message = BridgeMessage({
            messageType: BridgeMessageType.SINGLE_HOP_SEND,
            payload: abi.encode(
                SingleHopSendMessage({recipient: SOURCE_CHAIN_BURN_ADDRESS, amount: burnedTxFees})
                )
        });

        bytes32 messageID = _sendTeleporterMessage(
            TeleporterMessageInput({
                destinationBlockchainID: sourceBlockchainID,
                destinationAddress: tokenSourceAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(this), amount: reward}),
                requiredGasLimit: requiredGasLimit,
                allowedRelayerAddresses: new address[](0),
                message: abi.encode(message)
            })
        );

        emit ReportBurnedTxFees({teleporterMessageID: messageID, feesBurned: burnedTxFees});
    }

    /**
     * @dev See {IWrappedNativeToken-withdraw}.
     *
     * Note: {IWrappedNativeToken-withdraw} should not be confused with {TeleporterTokenDestination-_withdraw}.
     * {IWrappedNativeToken-withdraw} is the external method to redeem a wrapped native token (ERC20) balance
     * for the native token itself. {TeleporterTokenDestination-_withdraw} is the internal method used when
     * processing bridge transfers.
     */
    function withdraw(uint256 amount) external {
        emit Withdrawal(_msgSender(), amount);
        _burn(_msgSender(), amount);
        payable(_msgSender()).sendValue(amount);
    }

    /**
     * @dev See {IWrappedNativeToken-deposit}.
     *
     * Note: {IWrappedNativeToken-deposit} should not be confused with {TeleporterTokenDestination-_deposit}.
     * {IWrappedNativeToken-deposit} is the public method for converting native tokens into the wrapped native
     * token (ERC20) representation. {TeleporterTokenDestination-_deposit} is the internal method used when
     * processing bridge transfers.
     */
    function deposit() public payable {
        emit Deposit(_msgSender(), msg.value);
        _mint(_msgSender(), msg.value);
    }

    /**
     * @dev See {INativeTokenDestination-totalNativeAssetSupply}.
     *
     * Note: {INativeTokenDestination-totalNativeAssetSupply} should not be confused with {IERC20-totalSupply}
     * {INativeTokenDestination-totalNativeAssetSupply} returns the supply of the native asset of the chain,
     * accounting for the amounts that have been bridged in and out of the chain as well as burnt transaction
     * fees. The {initialReserveBalance} is included in this supply since it is in circulation on this
     * chain even prior to it being backed by collateral on the source chain.
     * {IERC20-totalSupply} returns the supply of the native asset held by this contract
     * that is represented as an ERC20.
     */
    function totalNativeAssetSupply() public view returns (uint256) {
        uint256 burned = BURNED_TX_FEES_ADDRESS.balance + BURNED_FOR_BRIDGE_ADDRESS.balance;
        uint256 created = totalMinted + initialReserveImbalance;
        return created - burned;
    }

    /**
     * @dev See {TeleporterTokenDestination-_deposit}
     *
     * Native tokens to be deposited are sent via the payable {send} and {sendAndCall} functions, and
     * remained locked in this contract. The internal call to {_mint} here credits the full amount as
     * the wrapped native asset (ERC20) token by incrementing the ERC20 balance of this contract, such
     * that it can be used to pay for message fees if needed.
     */
    function _deposit(uint256 amount) internal virtual override returns (uint256) {
        _mint(address(this), amount);
        return amount;
    }

    /**
     * @dev See {TeleporterTokenDestination-_withdraw}
     */
    function _withdraw(address recipient, uint256 amount) internal virtual override {
        // `amount` isn't expected to be zero, since the source bridge contract
        // checks whether the scaled amount is non-zero before sending the message.
        emit TokensWithdrawn(recipient, amount);
        _mintNativeCoin(recipient, amount);
    }

    /**
     * @dev See {TeleporterTokenDestination-_burn}
     *
     * This is the internal {_burn} method called when bridging tokens to another chain.
     * The tokens to be burnt are already be held by this contract, and credited to this
     * contract's balance of the wrapped native token. To burn the tokens, first burn the
     * wrapped ERC20 representation of the native token (decreasing the totalSupply of the
     * wrappen native token and reducing this contract's balance of it), and then send the
     * native token amount to the BURNED_FOR_BRIDGE_ADDRESS.
     *
     */
    function _burn(uint256 amount) internal virtual override {
        _burn(address(this), amount);
        payable(BURNED_FOR_BRIDGE_ADDRESS).sendValue(amount);
    }

    /**
     * @dev See {TeleporterTokenDestination-_handleSendAndCall}
     *
     * Mints the tokens to this contract, and send them to the recipient contract as a
     * part of the call to {INativeSendAndCallReceiver-receiveTokens} on the recipient contract.
     * If the call fails, the amount is sent to the fallback recipient.
     *
     * Note: If the recipient contract does not properly handle the full msg.value sent,
     * the balance can be locked in the recipient contract. Receiving contracts must make
     * sure to properly handle the balance to ensure it does not get locked improperly.
     */
    function _handleSendAndCall(
        SingleHopCallMessage memory message,
        uint256 amount
    ) internal virtual override {
        // Mint the tokens to this contract address.
        _mintNativeCoin(address(this), amount);

        // Encode the call to {INativeSendAndCallReceiver-receiveTokens}
        bytes memory payload = abi.encodeCall(
            INativeSendAndCallReceiver.receiveTokens,
            (
                message.sourceBlockchainID,
                message.originBridgeAddress,
                message.originSenderAddress,
                message.recipientPayload
            )
        );

        // Call the destination contract with the given payload, gas amount, and value.
        bool success = CallUtils._callWithExactGasAndValue(
            message.recipientGasLimit, amount, message.recipientContract, payload
        );

        // If the call failed, send the funds to the fallback recipient.
        if (success) {
            emit CallSucceeded(message.recipientContract, amount);
        } else {
            emit CallFailed(message.recipientContract, amount);
            payable(message.fallbackRecipient).sendValue(amount);
        }
    }

    /**
     * @dev Mints coins to the recipient through the NativeMinter precompile.
     */
    function _mintNativeCoin(address recipient, uint256 amount) private {
        totalMinted += amount;
        // Calls NativeMinter precompile through INativeMinter interface.
        NATIVE_MINTER.mintNativeCoin(recipient, amount);
    }
}
