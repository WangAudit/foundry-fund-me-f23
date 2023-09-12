// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {

        HelperConfig helperConfig = new HelperConfig(); //we created a helper config to use it
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();//we get the address of price feed

        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return (fundMe);
    }
}
