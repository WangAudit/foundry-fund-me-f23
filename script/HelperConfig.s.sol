/*
    1. Deploy mocks when we are on a local anil chain
    2. Keep track of contract address across different chains
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //if we are on a local anvil chain, we deploy mocks
    //otherwise, grab the existing address from the network

    NetworkConfig public activeNetworkConfig; // so we can set what network config to use

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8; // these are magic nubmers we us in mock, so we don't want to forget them we declare them here as variables

    constructor() { //when we deploy a contract we tell it which config to use via chain Id
        if (block.chainid == 11155111) { //sepolia chain Id
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreatAnvilEthConfig();
        }
    }
 
    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;   
    }

    function getOrCreatAnvilEthConfig() public returns (NetworkConfig memory) {
        //price feed address

        //Deploy a mock - fake contract
        //Then, return mocks address

        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig; // so if we already set the mock address, we don't creat a new one
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator (
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}