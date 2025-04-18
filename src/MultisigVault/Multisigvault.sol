// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {VaultNFT} from "../VaultNft.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Multisig} from "./multisigWallet.sol";
import {ILendingPool} from "../Interfaces/ILendingPool.sol";

contract MultiSigVault is Multisig, ReentrancyGuard{
    event WithDrawnFromTimeLockVault(address indexed user,uint256 amount,IERC20 token);
    
    Multisig public multisig;
    ILendingPool public lendingPool;
    address public treasury;

    VaultNFT public vaultNFT;
    bool private intialized;
    constructor() Multisig(3){}
    function intialize(VaultNFT _vaultnft,address multisigaddress,address _lendingPool,address _treasury) external {
        require(!intialized, "Already initialized");
        vaultNFT = _vaultnft;
        multisig = Multisig(multisigaddress);
        lendingPool = ILendingPool(_lendingPool); // Aave LendingPool address (get from testnet docs)
        treasury = _treasury;
        intialized = true;
    }

    struct VaultInfo{
        IERC20 token;
        uint256 amount;
        address[] signers;
       

    }
    mapping(uint256 => VaultInfo) private vaults;
    mapping(address => uint256[]) private vaultID;


    
    function lockFundsUsingMultiSig(address user,uint256 amounttolock,IERC20 token) external returns(uint256){
        IERC20(token).transferFrom(user, address(this), amounttolock);
        IERC20(token).approve(address(lendingPool), amounttolock);
        lendingPool.deposit(address(token), amounttolock, address(this), 0);

        uint256 vaultId = _mintNFT(user);
        vaults[vaultId] = VaultInfo({
            token: token,
            amount: amounttolock,
            signers: owners
            
        });
        return vaultId;


    }


    function withdrawFromMultiSigVault(uint256 vaultId) external nonReentrant {
        VaultInfo storage vault = vaults[vaultId];
        require(vault.amount > 0, "No funds to withdraw");
        bool isApproved = multisig.approve(vaultId);
        if(!isApproved) {
            revert("Not enough approvals");

        }
        uint256 amount = vault.amount;
        vault.amount = 0;
        uint256 withdrawn = lendingPool.withdraw(address(vault.token), amount, address(this));

        //  Calculate yield + protocol fee
        uint256 earned = withdrawn - amount;
        uint256 fee = earned / 10; // 10% protocol cut

        //  Transfer user share
        vault.token.transfer(msg.sender, withdrawn - fee);

        //  Transfer protocol fee to treasury
        vault.token.transfer(treasury, fee);   
        emit WithDrawnFromTimeLockVault(msg.sender, amount, vault.token);

    }
    
    
    
    //internal functions
  
    function _mintNFT(address user) internal returns (uint256) {
        return vaultNFT.mint(user,10);
    }


    function getVaultInfo(uint256 tokenid) external view returns (VaultInfo memory) {
        return vaults[tokenid];
    }

    function getVaultValue(uint256 vaultId) external view returns (uint256) {
    return vaults[vaultId].amount;
}


}