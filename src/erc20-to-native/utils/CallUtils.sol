// (c) 2024, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem
pragma solidity 0.8.18;

library CallUtils {
    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function _callWithExactGas(
        uint256 gasAmount,
        address target,
        bytes memory data
    ) internal returns (bool) {
        return _callWithExactGasAndValue(gasAmount, 0, target, data);
    }

    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function _callWithExactGasAndValue(
        uint256 gasAmount,
        uint256 value,
        address target,
        bytes memory data
    ) internal returns (bool) {
        require(gasleft() >= gasAmount, "CallUtils: insufficient gas");
        require(address(this).balance >= value, "CallUtils: insufficient value");

        // If there is no code at the target, automatically consider the call to have failed since it
        // doesn't have any effect on state.
        if (target.code.length == 0) {
            return false;
        }

        // Call the destination address of the message with the provided data and amount of gas.
        //
        // Assembly is used for the low-level call to avoid unnecessary expansion of the return data in memory.
        // This prevents possible "return bomb" vectors where the external contract could force the caller
        // to use an arbitrary amount of gas. See Solidity issue here: https://github.com/ethereum/solidity/issues/12306
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success :=
                call(
                    gasAmount, // gas provided to the call
                    target, // call target
                    value, // value transferred
                    add(data, 0x20), // input data - 0x20 needs to be added to an array because the first 32-byte slot contains the array length (0x20 in hex is 32 in decimal).
                    mload(data), // input data size - mload returns mem[p..(p+32)], which is the first 32-byte slot of the array. In this case, the array length.
                    0, // output
                    0 // output size
                )
        }
        return success;
    }
}
