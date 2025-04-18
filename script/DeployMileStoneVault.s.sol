// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;



import {MilestoneVault} from "../src/Milestonevault.sol";
import {VaultNFT} from "../src/VaultNft.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
contract DeployMilestoneVault is Script {
    HelperConfig config = new HelperConfig();
    HelperConfig.NetworkConfig networkConfig = config.getActiveNetworkConfig();
    address lendingPool = networkConfig.lendingPool;
    address treasury = networkConfig.treasury;
    function run() external returns(MilestoneVault, VaultNFT){
        vm.startBroadcast();
        VaultNFT vaultNFT = new VaultNFT();
        MilestoneVault milestoneVault = new MilestoneVault(vaultNFT,lendingPool, treasury);
        vaultNFT.transferOwnership(address(milestoneVault));
        vm.stopBroadcast();
        return (milestoneVault, vaultNFT);
    }
}