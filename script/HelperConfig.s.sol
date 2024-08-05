// SPDX-License-Identifier: MIT


// Deploy mocks when we are on a anvil chain
// Keep track of contract address across different chains.

//Sepolia ETH/USD - diff address
//Mainnet ETH/USD -diff address

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address pricefeed; //ETH/USD pricefeed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //pricefeed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            pricefeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

     function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.pricefeed != address(0)){
            return activeNetworkConfig;
        }
        
        // price feed address

        //1. Deploy the mocks
        //2. Return the mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS, 
            INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            pricefeed: address(mockPriceFeed)});
        return anvilConfig;
     }

}