// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {MultiSigVault} from "src/MultisigVault/Multisigvault.sol";
import {VaultNFT} from "src/VaultNft.sol";
import {Multisig} from "src/MultisigVault/multisigWallet.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployMultiSigVault is Script{


    function run() external returns(MultiSigVault){
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        address lendingPool = networkConfig.lendingPool;
        address treasury = networkConfig.treasury;
        vm.startBroadcast();
        VaultNFT vaultNFT = new VaultNFT();
        Multisig multisig = new Multisig(3);
        MultiSigVault multiSigVault = new MultiSigVault();
        multiSigVault.intialize(vaultNFT, address(multisig), lendingPool, treasury);
        vaultNFT.transferOwnership(address(multiSigVault));
        vm.stopBroadcast();
        return multiSigVault;
    }
}
