// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockLendingPool} from "test/mocks/MockLendingPool.sol";

contract HelperConfig is Script {

    struct NetworkConfig {
        address lendingPool;
        address treasury;
        address[] allowedTokens;
    }

    NetworkConfig public activeNetworkConfig;


    address constant SEPOLIA_LENDING_POOL = 0xc13E21b648A5aAAa0c92B36c3f4b5d1EC8c5a5e3;
    address constant DEAFULT_TREASURY = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;
    constructor() {
        networkConfigs[11155111] = getSepoliaConfig();
        networkConfigs[31337] = getOrCreateAnvilConfig();

    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        if (activeNetworkConfig.lendingPool != address(0)) {
            return activeNetworkConfig;
        } else {
            return networkConfigs[block.chainid];
        }
    }



    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        address[] memory allowed = new address[](3);
        allowed[0] = 0xdd13E55209Fd76AfE204dBda4007C227904f0a81; // WETH
        allowed[1] = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // USDC
        allowed[2] = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844; // DAI
        return NetworkConfig({
            lendingPool: SEPOLIA_LENDING_POOL,
            treasury: DEAFULT_TREASURY,
            allowedTokens: allowed
               

        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.lendingPool != address(0)) {
            return activeNetworkConfig;
        } 
        
        vm.startBroadcast();
        MockLendingPool mockLendingPool = new MockLendingPool();
        ERC20Mock weth = new ERC20Mock("Wrapped Ether", "WETH", msg.sender, 1_000_000 ether);
        ERC20Mock usdc = new ERC20Mock("USD Coin", "USDC", msg.sender, 1_000_000 * 1e6); // USDC is 6 decimals
        ERC20Mock dai  = new ERC20Mock("Dai Stablecoin", "DAI", msg.sender, 1_000_000 ether);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
        lendingPool: address(mockLendingPool),
        treasury: DEAFULT_TREASURY
        });

    activeNetworkConfig = anvilConfig;
    return anvilConfig;

    }


}