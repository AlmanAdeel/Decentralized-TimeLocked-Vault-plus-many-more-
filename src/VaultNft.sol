// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract VaultNFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;
    mapping(uint256 => uint256) public tokenPrices;

    constructor() ERC721("VaultNFT", "VAULT") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    function mint(address to, uint256 priceinUSD) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        tokenPrices[tokenId] = priceinUSD;
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        _burn(tokenId);
    }

    function getUsdPrice(uint256 tokenId) external view returns (uint256) {
        return tokenPrices[tokenId];
    }
}
