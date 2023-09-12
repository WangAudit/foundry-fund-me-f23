// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol"; //we add .. bcs we want to specify that we go down to the directory
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 constant SEND_VALUE = 0.1 ether; //magic number

    address USER = makeAddr("user"); //we created an address to check how the transactions work, only in foundry
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1; 

    function setUp() external {
        // us -> FundMeTest -> fundMe, so the contract FundMeTest is the owner of the fundMe because it deployed the contract
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinDollarIsFive() public {
        assertEq(fundMe.minUsd(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // console.log(fundMe.i_owner());
        // console.log(msg.sender);
        //we use address(this), because FundMeTest is the owner of fundMe and address(this) refers to the address of this contract
        //assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    /*
        What can we do to work with address outside our system?
        1. Unit
            - Testing a specific part of our code
            - forge test --match-test *functionName* -vvv
        2. Integration
            - Testing how our code works with other parts of our code
        3. Forked
            - Testing our code on a simualted real environment
            - it simulates a chain and runs test our function there
            - forge test --match-test testPriceFeedVersion -vvv --fork-url $SEPOLIA_RPC_URL
        4. Staging
            - Testing our code in a real environment that is not prod

        we use forge coverage --fork-url $SEPOLIA_RPC_URL to see how much of out code is tested
    */

    function testPriceFeedVersion() public {
        uint256 version = fundMe.getVersion(); //if there is a fail add -vvv to see more info about the function
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey, the next line, should revert, i. e. it should fail
        fundMe.fund(); // it should fail because we send 0 ETH
        // to send ETH we should say fundMe.fund{value: smth}();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next txn is sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() { //now we don't need to write it every time.
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdraWithASingleFunder() public {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert   
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++ ) {
            hoax(address(i), SEND_VALUE); //hoax is a combination between vm.prank and vm.deal
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 gasStart = gasleft(); //we can calculate how much gas the transac cost
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; we get the difference of how much gas is left and multiply it by
                                                                //txn cost
        // console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);

    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++ ) {
            hoax(address(i), SEND_VALUE); //hoax is a combination between vm.prank and vm.deal
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 gasStart = gasleft(); //we can calculate how much gas the transac cost
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; we get the difference of how much gas is left and multiply it by
                                                                //txn cost
        // console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);

    }
}
