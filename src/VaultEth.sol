// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VaultETH is ERC20 {
    address public owner;

    constructor() ERC20("Vault ETH", "vETH") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Not authorized");
        _mint(to, amount);
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only current owner");
        owner = newOwner;
    }
}
