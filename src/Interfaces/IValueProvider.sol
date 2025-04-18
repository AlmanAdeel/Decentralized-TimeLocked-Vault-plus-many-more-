// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IValueProvider {
    function getVaultValue(uint256 tokenId) external view returns (uint256);
}
