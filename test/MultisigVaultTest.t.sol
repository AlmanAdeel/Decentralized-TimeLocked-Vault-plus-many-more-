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

import {Test} from "forge-std/Test.sol";
import {MultiSigVault} from "../src/MultisigVault/Multisigvault.sol";
import {Multisig} from "../src/MultisigVault/multisigWallet.sol";
import {VaultNFT} from "../src/VaultNft.sol";
import {MockLendingPool} from "./mocks/MockLendingPool.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract MultisigVaultTest is Test {
    Multisig multisig;
    MultiSigVault multisigvault;
    VaultNFT vaultnft;
    MockLendingPool lendingPool;
    ERC20Mock token;
    address user = makeAddr("user");
    HelperConfig config;
    address owner1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address owner2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address owner3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function setUp() public {
        vaultnft = new VaultNFT();
        config = new HelperConfig();
        multisig = new Multisig(3);
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        address lendingPoolAddress = networkConfig.lendingPool;
        address treasury = networkConfig.treasury;
        token = new ERC20Mock("test", "t", user, 100 * 1e18);
        multisigvault = new MultiSigVault();
        multisigvault.intialize(vaultnft, address(multisig), lendingPoolAddress, treasury);
        vaultnft.transferOwnership(address(multisigvault));
        vm.startPrank(user);
        token.approve(address(multisigvault), type(uint256).max);
        vm.stopPrank();
        vm.deal(user, 100 ether);
    }

    function testCanLockFunds() public {
        uint256 vaultid = multisigvault.lockFundsUsingMultiSig(user, 50 * 1e18, token);
        MultiSigVault.VaultInfo memory vaultInfo = multisigvault.getVaultInfo(vaultid);
        ERC20Mock tokens = ERC20Mock(address(vaultInfo.token));
        uint256 amount = vaultInfo.amount;
        address[] memory signers = vaultInfo.signers;
        assertEq(address(tokens), address(token));
        assertEq(amount, 50 * 1e18);
        assertEq(signers[0], 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        assertEq(signers[1], 0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    }

    function testCanWithdrawFunds() public {
        uint256 vaultid = multisigvault.lockFundsUsingMultiSig(user, 50 * 1e18, token);
        MockLendingPool mock = MockLendingPool(config.getActiveNetworkConfig().lendingPool);
        mock.setVaultType(address(multisigvault), MockLendingPool.WithdrawType.MultiSig);
        mock.setMockYield(address(token), address(multisigvault), 10 ether);
        uint256 balanceBefore = token.balanceOf(user);
        uint256 treasuryBefore = token.balanceOf(config.getActiveNetworkConfig().treasury);
        vm.prank(owner1);
        multisig.approve(vaultid);
        vm.prank(owner2);
        multisig.approve(vaultid);
        vm.prank(owner3);
        multisig.approve(vaultid);

        vm.prank(user);
        multisigvault.withdrawFromMultiSigVault(vaultid);

        uint256 balanceAfter = token.balanceOf(user);
        uint256 treasuryAfter = token.balanceOf(config.getActiveNetworkConfig().treasury);
        uint256 expectedAmount = (50 ether + 10 ether) - 1 ether;
        uint256 expectedTreasury = 1 ether;
        assertEq(balanceAfter - balanceBefore, expectedAmount);
        assertEq(treasuryAfter - treasuryBefore, expectedTreasury);
    }
}
