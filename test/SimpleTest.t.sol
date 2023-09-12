// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

contract FundMeTest is Test {
    uint256 number = 1;

    function setUp() external {
        number++;
    }

    function testDemo() public {
        console.log(number); // to show console logs add -vv when start testing
        assertEq(number, 2);
    }
}
