// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;


import {IVaultNFT} from "./Interfaces/IValutNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VaultNFT} from "./VaultNft.sol";
import {ILendingPool} from "./Interfaces/ILendingPool.sol";

contract TimeLockVault is ReentrancyGuard {
    error TimeLockVault__EnterAValidTimeLimit();
    error TimeLockVault__PleaseEnterAccurateVaultID();
    event VaultCreated(address indexed user,uint256 amount,uint256 unlockTime,IERC20 token);
    event WithDrawnFromTimeLockVault(address indexed user,uint256 amount,IERC20 token);
    struct VaultInfo{
        IERC20 token;
        uint256 amount;
        uint256 unlockTime;
        bool isUnlocked;
    }
    //VaultInfo private vaultInfo;
    mapping(uint256 =>  VaultInfo) private vaults;
    mapping(address => uint256) public unlockTime;
    mapping(address => uint256[]) private vaultID;
   
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


    function lockFundsUsingTimeLock(address user,uint256 amountToLock,uint256 unlocktimeInDays,IERC20 token) external returns(uint256){
        bool lockTimeValid = _getTimeLimit(unlocktimeInDays * 1 days);
        if (!lockTimeValid) {
            revert TimeLockVault__EnterAValidTimeLimit();
        }
        IERC20(token).transferFrom(user, address(this), amountToLock);
        IERC20(token).approve(address(lendingPool), amountToLock);
        lendingPool.deposit(address(token), amountToLock, address(this), 0);
        unlockTime[user] = block.timestamp + (unlocktimeInDays * 1 days);
        uint256 vaultId = _mintNFT(user);
        vaultID[user].push(vaultId);
        emit VaultCreated(user, amountToLock, unlockTime[user], token);
        vaults[vaultId] = VaultInfo({
            token: token,
            amount: amountToLock,
            unlockTime: unlockTime[user],
            isUnlocked: false
        });
        return vaultId;


    }

    function withdrawFromTimeLockVault(uint256 vaultid) external payable nonReentrant {
        if(vaultid == 0) {
            revert TimeLockVault__PleaseEnterAccurateVaultID();
        }
        
        VaultInfo storage vault = vaults[vaultid];
        require(vault.amount > 0, "No funds to withdraw");
        require(block.timestamp >= vault.unlockTime, "Funds are still locked");
        require(!vault.isUnlocked, "Funds already withdrawn");

        vault.isUnlocked = true;
        // 🔥 Withdraw from Aave
        uint256 withdrawn = lendingPool.withdraw(address(vault.token), vault.amount, address(this));

        // 🔄 Optional fee logic
        uint256 fee = 0;
        uint256 userAmount = withdrawn;

        if (withdrawn > vault.amount) {
            uint256 earned = withdrawn - vault.amount;
            fee = earned / 10;
            userAmount = withdrawn - fee;

            vault.token.transfer(treasury, fee);
        }

        // ✅ Transfer final amount to user
        vault.token.transfer(msg.sender, userAmount);
            emit WithDrawnFromTimeLockVault(msg.sender, vault.amount, vault.token);
        }

    ///internal functions


    function _getTimeLimit(uint256 unlocktime) internal pure returns (bool) {
        if (unlocktime == 7 days) {
            return true;
        } else if (unlocktime == 30 days) {
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

    function _mintNFT(address user) internal returns (uint256) {
        return vaultNFT.mint(user,10);
    }
   // //getter functions

    // function getmintnft(address user) external returns(uint256){
    //     return _mintNFT(user);
    // }

    // function getVaultId(address user,uint256 tokenid) external view returns(uint256 vaultId)  {
    //     uint256[] memory tokens = vaultID[user];
    //     for(uint256 i = 0; i < tokens.length; i++) {
    //         if(tokens[i] == tokenid) {
    //             return tokenid;
    //         }
    //     }
    //     revert("Token ID not found");
    // }
    function getVaultsInfo(uint256 tokenid) external view returns(VaultInfo memory){
        return vaults[tokenid];
    }

      function getLendingPool() external view returns (address) {
    return address(lendingPool);
}
function getVaultValue(uint256 vaultId) external view returns (uint256) {
    return vaults[vaultId].amount;
}

    
        
    
 

}