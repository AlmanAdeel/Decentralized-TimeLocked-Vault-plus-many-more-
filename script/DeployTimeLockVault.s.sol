// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {TimeLockVault} from "../src/TimeLockVault.sol";
import {VaultNFT} from "../src/VaultNft.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployTimeLockVault is Script {
    function run() external returns(TimeLockVault){
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        address lendingPool = networkConfig.lendingPool;
        address treasury = networkConfig.treasury;
        vm.startBroadcast();

        VaultNFT vaultNFT = new VaultNFT();
        TimeLockVault timeLockVault = new TimeLockVault();
        timeLockVault.intialize(vaultNFT, lendingPool, treasury);
        vaultNFT.transferOwnership(address(timeLockVault));
        vm.stopBroadcast();
        return timeLockVault;

        
    }
}