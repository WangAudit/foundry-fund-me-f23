// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//we created a library, so our fundme contract looks cleaner and we can use this library for other contracts to get the price for eth.

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData(); //latestRoundData give a lot of outputs, so we have to define which one we need
        //we specified what we need, and gave a name to this variable price
        //price has only 8 decimals, but we need 18
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        //1 ETH?
        //2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);
        //(2000_000000000000000000 * 1_000000000000000000) / 1_000000000000000000
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
            //we get version of the pricefeed for ETH/USD from that address
    }
}
