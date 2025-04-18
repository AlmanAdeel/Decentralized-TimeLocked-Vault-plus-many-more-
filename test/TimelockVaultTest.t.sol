// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/*These tests were written before the VaultFactory contract was introduced, 
    so they are not based on the current factory-based deployment structure.

    At the time, each vault was deployed and tested individually to ensure 
    that their core functionalities were working as intended.

    Since then, changes have been made and the VaultFactory is now the primary 
    contract used to deploy vaults. If you notice any inconsistencies between 
    these tests and the current codebase, don't worry — all core vault 
    functionalities have already been validated.

    These tests are here for reference and for verifying the standalone 
    behavior of each vault contract.


 */




import {Test,console} from "forge-std/Test.sol";
import {TimeLockVault} from "../src/TimeLockVault.sol";
import {VaultNFT} from "../src/VaultNft.sol";
import {DeployTimeLockVault} from "../script/DeployTimeLockVault.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import{HelperConfig} from "script/HelperConfig.s.sol";
import {MockLendingPool} from "test/mocks/MockLendingPool.sol";

contract TimeLockTest is Test{
    VaultNFT vaultnft;
    TimeLockVault timelockvault;
    DeployTimeLockVault deployer;
    ERC20Mock token;
    address user = makeAddr("user");
    HelperConfig config;
    function setUp() public {
        vaultnft = new VaultNFT();
        config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        address lendingPool = networkConfig.lendingPool;
        address treasury = networkConfig.treasury;
        
        
        token = new ERC20Mock(user,100 * 1e18);
        timelockvault = new TimeLockVault(vaultnft,lendingPool, treasury);
        vaultnft.transferOwnership(address(timelockvault));
        vm.startPrank(user);
        token.approve(address(timelockvault), type(uint256).max);
        console.log("TimelockVault address: ", address(timelockvault));
        vm.stopPrank();
        console.log("Vaults internal lendingPool: ", timelockvault.getLendingPool());
        vm.deal(user, 100 ether);
    }


    function testrevertsWhenWrongTimeLimit() public {
        vm.expectRevert();
        timelockvault.lockFundsUsingTimeLock(user,50 * 1e18,9,token);
        
        
    }

    function testCanLockFunds() public {
        uint256 nowtime = block.timestamp;
        vm.prank(user);
        uint256 vaultId = timelockvault.lockFundsUsingTimeLock(user,50 * 1e18,7,token);
        TimeLockVault.VaultInfo memory vaultInfo = timelockvault.getVaultsInfo(vaultId);
        ERC20Mock tokens = ERC20Mock(address(vaultInfo.token));
        uint256 amount = vaultInfo.amount;
        uint256 unlocktime = vaultInfo.unlockTime;
        bool isunlocked = vaultInfo.isUnlocked;
        assertEq(address(tokens), address(token));
        assertEq(amount, 50 * 1e18);
        assertEq(unlocktime,nowtime + 7 days);
        assertEq(isunlocked,false);
    }

    function testRevertWhenTokenIdIsZero() public {
        vm.expectRevert();
        timelockvault.withdrawFromTimeLockVault(0);
    }

    function testWithdraw() public {
        vm.prank(user);
        uint256 vaultId = timelockvault.lockFundsUsingTimeLock(user,50 * 1e18,7,token);
        MockLendingPool mock = MockLendingPool(config.getActiveNetworkConfig().lendingPool);
        mock.setVaultType(address(timelockvault),MockLendingPool.WithdrawType.Timelock);
        mock.setMockYield(address(token),address(timelockvault), 10 ether);
        vm.warp(block.timestamp + 7 days);
        uint256 balanceBefore = token.balanceOf(user);
        uint256 treasuryBefore = token.balanceOf(config.getActiveNetworkConfig().treasury);
        vm.prank(user);
        timelockvault.withdrawFromTimeLockVault(vaultId);
        uint256 balanceAfter = token.balanceOf(user);
        uint256 treasuryAfter = token.balanceOf(config.getActiveNetworkConfig().treasury);
        uint256 expectedusergain = (50 ether + 10 ether) - 1 ether;
        uint256 expectedtreasury = 1 ether;
        assertEq(balanceAfter - balanceBefore, expectedusergain);
        assertEq(treasuryAfter - treasuryBefore, expectedtreasury); 
    } 
}