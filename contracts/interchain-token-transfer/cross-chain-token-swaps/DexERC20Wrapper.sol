// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import {IERC20SendAndCallReceiver} from "@avalanche-interchain-token-transfer/interfaces/IERC20SendAndCallReceiver.sol";
import {SafeERC20TransferFrom} from "@avalanche-interchain-token-transfer/utils/SafeERC20TransferFrom.sol";

import {SafeERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts@4.8.1/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts@4.8.1/utils/Context.sol";

import {IWAVAX} from "./interfaces/IWAVAX.sol";
import {IUniswapFactory} from "./interfaces/IUniswapFactory.sol";
import {IUniswapPair} from "./interfaces/IUniswapPair.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract DexERC20Wrapper is Context, IERC20SendAndCallReceiver {
    using SafeERC20 for IERC20;

    address public immutable WNATIVE;
    address public immutable factory;

    struct SwapOptions {
        address tokenOut;
        uint256 minAmountOut;
    }

    constructor(address wrappedNativeAddress, address dexFactoryAddress) {
        WNATIVE = wrappedNativeAddress;
        factory = dexFactoryAddress;
    }

    event TokensReceived(
        bytes32 indexed sourceBlockchainID,
        address indexed originTokenTransferrerAddress,
        address indexed originSenderAddress,
        address token,
        uint256 amount,
        bytes payload
    );

    // To receive native when another contract called.
    receive() external payable {}

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1e3 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function query(uint256 amountIn, address tokenIn, address tokenOut) internal view returns (uint256 amountOut) {
        if (tokenIn == tokenOut || amountIn == 0) {
            return 0;
        }
        address pair = IUniswapFactory(factory).getPair(tokenIn, tokenOut);
        if (pair == address(0)) {
            return 0;
        }
        (uint256 r0, uint256 r1,) = IUniswapPair(pair).getReserves();
        (uint256 reserveIn, uint256 reserveOut) = tokenIn < tokenOut ? (r0, r1) : (r1, r0);
        if (reserveIn > 0 && reserveOut > 0) {
            amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        }
    }

    function swap(uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut, address to) internal {
        address pair = IUniswapFactory(factory).getPair(tokenIn, tokenOut);
        (uint256 amount0Out, uint256 amount1Out) =
            (tokenIn < tokenOut) ? (uint256(0), amountOut) : (amountOut, uint256(0));
        IERC20(tokenIn).safeTransfer(pair, amountIn);
        IUniswapPair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function receiveTokens(
        bytes32 sourceBlockchainID,
        address originTokenTransferrerAddress,
        address originSenderAddress,
        address token,
        uint256 amount,
        bytes calldata payload
    ) external {
        emit TokensReceived({
            sourceBlockchainID: sourceBlockchainID,
            originTokenTransferrerAddress: originTokenTransferrerAddress,
            originSenderAddress: originSenderAddress,
            token: token,
            amount: amount,
            payload: payload
        });

        require(payload.length > 0, "DexERC20Wrapper: empty payload");

        IERC20 _token = IERC20(token);
        // Receives teleported assets to be used for different purposes.
        SafeERC20TransferFrom.safeTransferFrom(_token, _msgSender(), amount);

        // Requests a quote from the Uniswap V2-like contract.
        uint256 amountOut = query(amount, token, WNATIVE);
        require(amountOut > 0, "DexERC20Wrapper: insufficient liquidity");

        // Parses the payload of the message.
        SwapOptions memory swapOptions = abi.decode(payload, (SwapOptions));
        // Checks if the target swap price is still valid.
        require(amountOut >= swapOptions.minAmountOut, "DexERC20Wrapper: slippage exceeded");

        // Verifies if the desired tokenOut is a native or wrapped asset.
        if (swapOptions.tokenOut == address(0)) {
            swap(amount, amountOut, token, WNATIVE, address(this));
            IWAVAX(WNATIVE).withdraw(amountOut);
            payable(originSenderAddress).transfer(amountOut);
        } else {
            swap(amount, amountOut, token, WNATIVE, originSenderAddress);
        }
    }
}
