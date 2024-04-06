// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISHA256 {
    // Computes the SHA256 hash of value
    function hashWithSHA256(string memory value) external view returns (bytes32 hash);
}
