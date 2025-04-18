// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MockLendingPool {
    // Extended enum with 3 vault types
    enum WithdrawType { Timelock, Milestone, MultiSig }

    // Map vault address => type
    mapping(address => WithdrawType) public vaultTypes;

    // Map user => token => balance
    mapping(address => mapping(address => uint256)) public balances;

    // Withdrawal count for milestone logic
    mapping(address => uint256) public withdrawalCount;

    // Set vault type (called in test setup)
    function setVaultType(address vault, WithdrawType wType) external {
        vaultTypes[vault] = wType;
    }

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 /* _ */
    ) external {
        bool success = IERC20(asset).transferFrom(msg.sender, address(this), amount);
        require(success, "Deposit transfer failed");
        balances[onBehalfOf][asset] += amount;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256 returnAmount) {
        require(to != address(0), "Invalid recipient");
        uint256 currentBalance = balances[msg.sender][asset];
        require(currentBalance >= amount, "Not enough deposited");

        uint256 count = withdrawalCount[msg.sender];
        withdrawalCount[msg.sender] = count + 1;

        WithdrawType wType = vaultTypes[msg.sender];

        if (wType == WithdrawType.Timelock) {
            // Timelock: full withdrawal including yield
            if (currentBalance > amount) {
                returnAmount = currentBalance;
            } else {
                returnAmount = amount;
            }
        } else if (wType == WithdrawType.Milestone) {
            // Milestone: only partials, except last
            if (count == 3) {
                returnAmount = currentBalance;
            } else {
                returnAmount = amount;
            }
        } else if (wType == WithdrawType.MultiSig) {
            // MultiSig: full withdrawal including yield
            returnAmount = currentBalance;
        }

        balances[msg.sender][asset] = currentBalance - returnAmount;
        bool success = IERC20(asset).transfer(to, returnAmount);
        require(success, "Withdraw transfer failed");

        return returnAmount;
    }

    function setMockYield(
        address asset,
        address user,
        uint256 extraAmount
    ) external {
        balances[user][asset] += extraAmount;
        ERC20Mock(asset).mint(address(this), extraAmount);
    }
}
