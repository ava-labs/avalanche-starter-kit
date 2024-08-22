// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
import {ERC721} from "@openzeppelin/contracts@4.8.1/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts@4.8.1/token/ERC721/extensions/ERC721Burnable.sol";

contract ExampleERC721 is ERC721, ERC721Burnable {
    string private constant _TOKEN_NAME = "Mock Token";
    string private constant _TOKEN_SYMBOL = "EXMP";
    string private constant _TOKEN_URI = "https://example.com/ipfs/";

    constructor() ERC721(_TOKEN_NAME, _TOKEN_SYMBOL) {}

    function mint(uint256 tokenId) external {
        require(_ownerOf(tokenId) == address(0), "Token already minted");
        _mint(msg.sender, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _TOKEN_URI;
    }

    function baseUri() external pure returns (string memory) {
        return _TOKEN_URI;
    }
}
