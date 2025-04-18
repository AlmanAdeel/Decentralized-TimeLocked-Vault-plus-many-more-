// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {TimeLockVault} from "./TimeLockVault.sol";
import {MilestoneVault} from "./Milestonevault.sol";
import {MultiSigVault} from "./MultisigVault/Multisigvault.sol";
import {VaultNFT} from "./VaultNft.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Multisig} from "./MultisigVault/multisigWallet.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IValueProvider} from "./Interfaces/IValueProvider.sol";
contract VaultFactory is ReentrancyGuard {
    enum VaultType {
        TimeLock,
        Milestone,
        MultiSig}
    event VaultCreated(address indexed user, uint256 vaultId, VaultType vaultType, address vaultAddress);
    VaultNFT public vaultNFT;
    address public lendingPool;
    address public treasury;
    Multisig public multisig;
    address public owner;
    address public timeLockImplementation;
    address public milestoneImplementation;
    address public multiSigImplementation;
    mapping(address => address[]) public userVaults;
    mapping(address => bool) public allowedTokens;
    
    constructor(address _vaultNft,address _lendingpool,address _treasury,address _multisig,address _timelock,address _milestone,address _multisigvault) {
        vaultNFT = VaultNFT(_vaultNft);
        lendingPool = _lendingpool;
        treasury = _treasury;
        multisig = Multisig(_multisig);
        owner = msg.sender;
        timeLockImplementation = _timelock;
        milestoneImplementation = _milestone;
        multiSigImplementation = _multisigvault;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }


    function StoreInTimeLockVault(address user,uint256 amountToLock,uint256 unlocktimeInDays,IERC20 token) public returns(uint256 vaultid) {
        require(allowedTokens[address(token)], "Token not allowed");
        address clone = Clones.clone(timeLockImplementation);
        TimeLockVault timeLockVault = TimeLockVault(clone);
        timeLockVault.intialize(vaultNFT, lendingPool, treasury);
        vaultNFT.transferOwnership(address(timeLockVault));
        vaultid = timeLockVault.lockFundsUsingTimeLock(user, amountToLock, unlocktimeInDays, token);
        userVaults[user].push(address(timeLockVault));
        emit VaultCreated(user, vaultid, VaultType.TimeLock, address(timeLockVault));
    }

    function StoreInMileStoneVault(address user,uint256 amountToLock,IERC20 token,uint256 unlocktimeInDays) public returns(uint256 vaultid) {
        require(allowedTokens[address(token)], "Token not allowed");
        address clone = Clones.clone(milestoneImplementation);
        MilestoneVault milestoneVault = MilestoneVault(clone);
        milestoneVault.intialize(vaultNFT, lendingPool, treasury);
        vaultNFT.transferOwnership(address(milestoneVault));
        vaultid = milestoneVault.lockfundsUsingMileStone(user, amountToLock, token, unlocktimeInDays);
        userVaults[user].push(address(milestoneVault));
        emit VaultCreated(user, vaultid, VaultType.Milestone, address(milestoneVault));
    }

    function StoreInMultiSigVault(address user,uint256 amountToLock,IERC20 token) public returns(uint256 vaultid) {
        require(allowedTokens[address(token)], "Token not allowed");
        address clone = Clones.clone(multiSigImplementation);
        MultiSigVault multiSigVault = MultiSigVault(clone);
        multiSigVault.intialize(vaultNFT,address(multisig), lendingPool, treasury);
        vaultNFT.transferOwnership(address(multiSigVault));
        vaultid = multiSigVault.lockFundsUsingMultiSig(user, amountToLock, token);
        userVaults[user].push(address(multiSigVault));
        emit VaultCreated(user, vaultid, VaultType.MultiSig, address(multiSigVault));
    }


    function withdrawFromTimeLockVault(uint vaultIndex, uint256 vaultId) external nonReentrant {
    require(vaultIndex < userVaults[msg.sender].length, "Invalid vault index");
    address clone = userVaults[msg.sender][vaultIndex]; // get their specific cloned vault
    TimeLockVault(clone).withdrawFromTimeLockVault(vaultId); // call the logic on it
        }

    function withdrawFromMilestoneVault(uint vaultIndex, uint256 vaultId) external nonReentrant {
    require(vaultIndex < userVaults[msg.sender].length, "Invalid vault index");
    address clone = userVaults[msg.sender][vaultIndex]; // get their specific cloned vault
    MilestoneVault(clone).withdrawFromMilestoneVault(vaultId); // call the logic on it
        }

    function withdrawFromMultiSigVault(uint vaultIndex, uint256 vaultId) external nonReentrant {
    require(vaultIndex < userVaults[msg.sender].length, "Invalid vault index");
    address clone = userVaults[msg.sender][vaultIndex]; // get their specific cloned vault
    MultiSigVault(clone).withdrawFromMultiSigVault(vaultId); // call the logic on it
        }



    function addAllowedToken(address token) external onlyOwner {
        allowedTokens[token] = true;
    }
    function removeAllowedToken(address token) external onlyOwner {
        allowedTokens[token] = false;
    }
    function isAllowedToken(address token) external view returns (bool) {
        return allowedTokens[token];
    }

    ///getter functions
    function getUserVaults(address user) external view returns (address[] memory) {
        return userVaults[user];
    }

    function getVaultValue(address vaultAddress, uint256 vaultId) external view returns (uint256) {
        return IValueProvider(vaultAddress).getVaultValue(vaultId);
    }






    
}