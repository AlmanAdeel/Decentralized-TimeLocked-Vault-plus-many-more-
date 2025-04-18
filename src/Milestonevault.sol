// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VaultNFT} from "./VaultNft.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ILendingPool} from "./Interfaces/ILendingPool.sol";



contract MilestoneVault is ReentrancyGuard{
     error TimeLockVault__EnterAValidTimeLimit();
    error TimeLockVault__PleaseEnterAccurateVaultID();

    event WithDrawnFromTimeLockVault(address indexed user,uint256 amount,IERC20 token);

    uint256 private constant PRECISION = 10;
    VaultNFT public vaultNFT;
    ILendingPool public lendingPool;
    address public treasury;
    bool private intialized;
    // constructor(VaultNFT _vaultNFT,address _lendingPool,address _treasury) {
    //     vaultNFT = _vaultNFT;
    //     lendingPool = ILendingPool(_lendingPool); // Aave LendingPool address (get from testnet docs)
    //     treasury = _treasury;
    // }

    function intialize(VaultNFT _vaultnft,address _lendingPool,address _treasury) external {
        require(!intialized, "Already initialized");
        vaultNFT = _vaultnft;
        lendingPool = ILendingPool(_lendingPool); // Aave LendingPool address (get from testnet docs)
        treasury = _treasury;
        intialized = true;
    }

    struct Milestone {
        IERC20 token;
        uint256 amount;
        uint256 amountClaimed;
        uint256 milestonecount;
        uint256 milestoneDuration;
        uint256 unlockTime;
    }

    mapping(uint256 => Milestone) private milestones;
    mapping(uint256 tokenid => mapping(uint256 milestonenumber => uint256 milestonetime)) private milestonetime;
    mapping(uint256 => mapping(uint256 => uint256)) private milestoneamount;
    mapping(address => uint256[]) private vaultID;
 

    function lockfundsUsingMileStone(address user,uint256 amount,IERC20 token,uint256 unlocktimeInDays) external returns(uint256){
         bool lockTimeValid = _getTimeLimit(unlocktimeInDays * 1 days);
        if (!lockTimeValid) {
            revert TimeLockVault__EnterAValidTimeLimit();
        }
        if(address(token) == address(0)) {
            revert ("ZERO_TOKEN_ADDRESS");
        }
        IERC20(token).transferFrom(user, address(this), amount);
        IERC20(token).approve(address(lendingPool), amount);
        lendingPool.deposit(address(token), amount, address(this), 0);  
        uint256 vaultId = _mintNFT(user);
        vaultID[user].push(vaultId);
        (uint256 amountbymilestone,uint256 amountoflastmilestone,uint256 unlocktimeforonemilestone,uint256 timeforlast) = _calculateMilestone(amount, unlocktimeInDays);
       for (uint256 i = 0; i < 4; i++) {
        if (i < 3) {
        milestoneamount[vaultId][i] = amountbymilestone;
        milestonetime[vaultId][i] = unlocktimeforonemilestone * (i +1) * 1 days;
     } else {
        milestoneamount[vaultId][i] = amountoflastmilestone;
        milestonetime[vaultId][i] = block.timestamp + (timeforlast * 1 days);
     }
    }

        milestones[vaultId] = Milestone({
            token: token,
            amount: amount,
            amountClaimed: 0,
            milestonecount: 4,
            milestoneDuration: unlocktimeInDays * 1 days,
            unlockTime: block.timestamp + (unlocktimeInDays * 1 days)
        });
        return vaultId;
    }

    function withdrawFromMilestoneVault(uint256 vaultid) external payable nonReentrant {
        if(vaultid == 0) {
            revert TimeLockVault__PleaseEnterAccurateVaultID();
        }
        Milestone storage milestone = milestones[vaultid];
        require(milestone.amount > 0, "No funds to withdraw");
        uint256 count = milestone.milestonecount;
        for (uint256 i = 0; i < count; i++) {
            uint256 milestoneTime = milestonetime[vaultid][i];
            uint256 milestoneAmount = milestoneamount[vaultid][i];
            if (block.timestamp >= milestoneTime) {
                require(milestone.amountClaimed < milestone.amount, "All funds already withdrawn");
                require(milestoneAmount > 0, "No funds to withdraw");
                uint256 withdrawn = lendingPool.withdraw(address(milestone.token), milestoneAmount, address(this));

            // Optional: take 10% fee from yield if any (not milestoneAmount)
            uint256 fee = 0;
            uint256 userAmount = withdrawn;

            if (withdrawn > milestoneAmount) {
                uint256 earned = withdrawn - milestoneAmount;
                fee = earned / 10;
                userAmount = withdrawn - fee;
                     milestone.token.transfer(treasury, fee);
             }

                milestone.token.transfer(msg.sender, userAmount);
                milestone.amountClaimed += milestoneAmount;
                milestoneamount[vaultid][i] = 0;
            }
        }
        emit WithDrawnFromTimeLockVault(msg.sender, milestone.amountClaimed, milestone.token);
    }




    // internal functions
     function _getTimeLimit(uint256 unlocktime) internal pure returns (bool) {
       if (unlocktime == 30 days) {
            return true;
        } else if (unlocktime == 90 days) {
            return true;
        } else if (unlocktime == 180 days) {
            return true;
        } else if (unlocktime == 365 days) {
            return true;
        } else {
            return false;
        }
    }

    function _calculateMilestone(uint256 amount,uint256 unlocktime) internal pure returns (uint256,uint256,uint256,uint256) {
        uint256 amountforone = amount / 4;
        uint256 last = amount - (amountforone * 3);
        uint256 timeforone = unlocktime / 4;
        uint256 timeforlast = unlocktime - (timeforone * 3);
        return (amountforone, last, timeforone,timeforlast);


    }

    function _mintNFT(address user) internal returns (uint256) {
        return vaultNFT.mint(user,10);
    }



    //getters
    function getMilestoneInfo(uint256 vaultId) external view returns (Milestone memory) {
        return milestones[vaultId];
    }

    function getmileStoneTime(uint256 tokenId, uint256 milestoneNumber) external view returns (uint256) {
        return milestonetime[tokenId][milestoneNumber];
    }

    function getmilestoneamount(uint256 tokenid, uint256 milestoneNumber) external view returns (uint256) {
        return milestoneamount[tokenid][milestoneNumber];
    }

    function getLendingPool() external view returns (address) {
    return address(lendingPool);
}

function getVaultValue(uint256 vaultId) external view returns (uint256) {
    return milestones[vaultId].amount;
}

}