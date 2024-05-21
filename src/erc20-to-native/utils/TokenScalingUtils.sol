// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem
pragma solidity 0.8.18;

library TokenScalingUtils {
    /**
     * @notice Scales the {amount} of source tokens to the destination bridge's token scale.
     * @param tokenMultiplier The token multiplier of the destination bridge.
     * @param multiplyOnDestination Whether the amount of source tokens will be multiplied on the destination, or divided.
     * @param sourceTokenAmount The amount of source tokens to scale.
     */
    function applyTokenScale(
        uint256 tokenMultiplier,
        bool multiplyOnDestination,
        uint256 sourceTokenAmount
    ) internal pure returns (uint256) {
        return _scaleTokens(tokenMultiplier, multiplyOnDestination, sourceTokenAmount, true);
    }

    /**
     * @notice Removes the destination bridge's token scaling, and returns the corresponding
     * amount of source tokens.
     * @param tokenMultiplier The token multiplier of the destination bridge.
     * @param multiplyOnDestination Whether the amount of source tokens will be multiplied on the destination, or divided.
     * @param destinationTokenAmount The amount of destination tokens to remove scaling from.
     */
    function removeTokenScale(
        uint256 tokenMultiplier,
        bool multiplyOnDestination,
        uint256 destinationTokenAmount
    ) internal pure returns (uint256) {
        return _scaleTokens(tokenMultiplier, multiplyOnDestination, destinationTokenAmount, false);
    }

    /**
     * @dev Scales {value} based on {tokenMultiplier} and if the amount is applying or
     * removing the destination bridge's token scale.
     * Should be used for all tokens and fees being transferred to/from other subnets.
     * @param tokenMultiplier The token multiplier of the destination bridge.
     * @param multiplyOnDestination Whether the amount of source tokens will be multiplied on the destination, or divided.
     * @param amount The amount of tokens to scale.
     * @param isSendToDestination If true, indicates the amount is being sent to the
     * destination bridge, so applies token scale. If false, indicates the amount is being
     * sent back to the source bridge, so removes token scale.
     */
    function _scaleTokens(
        uint256 tokenMultiplier,
        bool multiplyOnDestination,
        uint256 amount,
        bool isSendToDestination
    ) private pure returns (uint256) {
        // Multiply when multiplyOnDestination and isSendToDestination are
        // both true or both false.
        if (multiplyOnDestination == isSendToDestination) {
            return amount * tokenMultiplier;
        }
        // Otherwise divide.
        return amount / tokenMultiplier;
    }
}
