/* 
    Plan:
    1. Get Funds from users.
    2. Withdraw Funds.
    3. Set a minimum funding value in USD.
*/

//822,138 - first deploy
//758,668 - second more gas efficient deploy
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
//we import directly from git hub
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//we made an interface of the onctract so we don't have to copy all of its functions and just direct to them

//we comment it out because we imported this interface from the github above^
// interface AggregatorV3Interface {
//   function decimals() external view returns (uint8);

//   function description() external view returns (string memory);

//   function version() external view returns (uint256);

//   function getRoundData(
//     uint80 _roundId
//   ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

//   function latestRoundData()
//     external
//     view
//     returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
// }

import {PriceConverter} from "./PriceConverter.sol";

//we also mention the contract name so it easier for us to navigate through it if we get an error
error FundMe__NotOwner(); // we created an error to replace the require statement, which will cost less gas

contract FundMe {
    using PriceConverter for uint256;

    //uint256 public myValue = 1;
    uint256 public constant minUsd = 5e18; // min usd to fund us. But to get ether in usd (msg.value is in ETH) we use oracles.
    //we need to have it 18 decimals, because amount in eth will have 18 decimals
    //we added constant keyword, so this variable doesn't take space in storage so it will cost less to deploy a contract

    address[] private s_funders; //we make an array to keep track of our funders
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded; //how many eth the address gave us
    
    AggregatorV3Interface private s_priceFeed;

    address private immutable i_owner; //since we reassign this variable only once, we can use immutable keyword, so it will cost less gas

    constructor(address priceFeed) {
        //the constructor is the function which is deployed as soon as we deploy our contract
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed); //so we can easily change the network we work on
    }

    function fund() public payable {
        //it is required that user has to fund with more than 1 eth.
        //myValue = myValue + 2; //if require get rejected, then it reverts our myValue back to 1.
        //require(getConversionRate(msg.value) >= minUsd, "Didn't send enough ETH"); //1e18 = 1 ETH = 1 * 10 ** 18 wei.
        //msg.value.getConversionRate();
        require(msg.value.getConversionRate(s_priceFeed) >= minUsd, "Didn't send enough ETH"); // this is two comments above together
        //getConversionRate function requires to input a parameter, but since we use it on msg.value, msg.value is the parameter we need
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
            //we get version of the pricefeed for ETH/USD from that address
    }

    function cheaperWithdraw() public onlyOwner { //we make a function so we read and write less from and in storage and save gas
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}(""); 
        require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0); // we resetting our funders array and startimg from 0 index.

        //msg.sender = address
        //payable(msg.sender) = payable address
        //payable(msg.sender).transfer(address(this).balance);// we transfer money from this address' (contract's address) balance to our balance msg.sender
        //transfer automatically reverts if it is failed

        //send - doesn't revert, just says it is failed
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send Failed"); //if it fails we will revert the txn and return money plus throw an error

        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}(""); // call() is used to call the functions from the ethereum
        //but since we want to use it to send a txn, we say that we want value of msg.sender to have balance of this address
        //call function returns two parameters, if the function was called and the data of that txn (bytes memory data)
        //but we only need callSuccess in our instance, so we don't write
        require(callSuccess, "Call Failed");
        //in our contract we want to use call()
    }

    modifier onlyOwner() {
        // we can add this modifier to functions and we don't need to write the line of the code everytime
        //require(msg.sender == i_owner, "Must be an owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //it means the modifier is finished and we can run the function itself
    }

    //if someone sends us money directly without using fund button
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    //View / pure functions, i. e. getters:

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns(uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
}
