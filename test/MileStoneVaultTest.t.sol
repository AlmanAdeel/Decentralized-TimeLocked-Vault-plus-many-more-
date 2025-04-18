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
import {MilestoneVault} from "../src/Milestonevault.sol";
import {VaultNFT} from "../src/VaultNft.sol";
import {DeployMilestoneVault} from "../script/DeployMileStoneVault.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MockLendingPool} from "test/mocks/MockLendingPool.sol";
contract MilestoneVaultTest is Test {
    VaultNFT vaultnft;
    MilestoneVault milestonevault;
    DeployMilestoneVault deployer;
    ERC20Mock token;
    address user = makeAddr("user");
    HelperConfig public config;
    function setUp() public {
        
        config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        address lendingPool = networkConfig.lendingPool;
        address treasury = networkConfig.treasury;
        console.log("Lending Pool from Config: ", networkConfig.lendingPool);

        token = new ERC20Mock(user,100 * 1e18);
        vaultnft = new VaultNFT();
        milestonevault = new MilestoneVault(vaultnft,lendingPool, treasury);
        vaultnft.transferOwnership(address(milestonevault));
        vm.startPrank(user);
        token.approve(address(milestonevault), type(uint256).max);
        console.log("MilestoneVault address: ", address(milestonevault));

        vm.stopPrank();
        console.log("Vaults internal lendingPool: ", milestonevault.getLendingPool());
        vm.deal(user, 100 ether);

    }


    function testCanLockFundInMileStoneVault() public {
        uint256 nowtime = block.timestamp;
        console.log("milestonevault address: ", address(milestonevault));
        console.log("token address: ", address(token));

        vm.prank(user);
        uint256 vaultId = milestonevault.lockfundsUsingMileStone(user,50 * 1e18,token,30);
        MilestoneVault.Milestone memory milestoneInfo = milestonevault.getMilestoneInfo(vaultId);
        ERC20Mock tokens = ERC20Mock(address(milestoneInfo.token));
        uint256 amount = milestoneInfo.amount;
        uint256 unlocktime = milestoneInfo.unlockTime;
        uint256 milestonecount = milestoneInfo.milestonecount;
        uint256 milestoneDuration = milestoneInfo.milestoneDuration;
        uint256 amountClaimed = milestoneInfo.amountClaimed;
        assertEq(address(tokens), address(token));
        assertEq(amount, 50 * 1e18);
        assertEq(unlocktime, nowtime + 30 days);
        assertEq(milestonecount, 4);
        assertEq(milestoneDuration, 30 days);
        assertEq(amountClaimed, 0);
        }

    function testCanWithdrawFundsFromMileStoneVault() public {
        vm.prank(user);
        uint256 vaultId = milestonevault.lockfundsUsingMileStone(user,50 * 1e18,token,30);
        


        MockLendingPool mock = MockLendingPool(config.getActiveNetworkConfig().lendingPool);
        mock.setVaultType(address(milestonevault),MockLendingPool.WithdrawType.Milestone);
        mock.setMockYield(address(token),address(milestonevault), 10 ether);
        vm.warp(block.timestamp + 30 days);
        uint256 balanceBefore = token.balanceOf(user);
        uint256 treasuryBefore = token.balanceOf(config.getActiveNetworkConfig().treasury);
        vm.prank(user);
        milestonevault.withdrawFromMilestoneVault(vaultId);

        uint256 balanceAfter = token.balanceOf(user);
        uint256 treasuryAfter = token.balanceOf(config.getActiveNetworkConfig().treasury);

        uint256 expectedUserGain = (50 ether + 10 ether) - 1 ether;
        uint256 expectedTreasuryGain = 1 ether;
        assertEq(balanceAfter - balanceBefore, expectedUserGain);
        assertEq(treasuryAfter - treasuryBefore, expectedTreasuryGain); 


        
       
    }


 
}